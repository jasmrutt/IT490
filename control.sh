#!/bin/bash

# =============================================================================
# Configuration
# =============================================================================

declare -a HOSTS
while IFS= read -r line; do
  host_name=$(echo "$line" | awk '{print $2}')
  if [[ "$host_name" =~ ^(droplet)-0[0-9]+$ ]]; then
    HOSTS+=("$host_name")
  fi
done < <(tailscale status)

readonly SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'

readonly RESET='\033[0m'

readonly BRIGHT='\033[1m' # bold
readonly DIM='\033[2m'    # 50/50 if this is supported...
readonly UNDERLINE='\033[4m'
readonly HIDDEN='\033[8m'
readonly BLINK='\033[5m'
readonly INVERT='\033[7m'

readonly REPO_URL="git@github.com:IT490-101FA24/Capstone-Group-09.git"
readonly REPO_BRANCH="main"
readonly REPO_PATH="/home/Capstone-Group-10"
# ^^ Should be /opt/applicare/ rather than in /home/Capstone-Group-09 -- but I don't want to have to explain how to change the path

readonly FRONTEND_PACKAGES=(
  nodejs
  npm
  # haproxy
  # ^^ I have no idea how Shak is handling reverse proxy / load balancing, but this is what I would use
)

readonly BACKEND_PACKAGES=(
  python3-full
  python3-aiopika
  python3-pika
)

readonly DATABASE_PACKAGES=(
  python3-full
  python3-mysql.connector
  python3-pika
  mariadb-server
  mariadb-client
  galera-4
  rsync
  mariadb-plugin-provider-bzip2
  mariadb-plugin-provider-lz4
  mariadb-plugin-provider-lzma
  mariadb-plugin-provider-lzo
  mariadb-plugin-provider-snappy
)

readonly COMMUNICATION_PACKAGES=(
  gnupg
  erlang
  rabbitmq-server
)

# =============================================================================
# Helper Functions
# =============================================================================

print_status() {
  local status=$1
  local message=$2
  local quiet_mode=$3

  if [[ "$quiet_mode" != "true" ]]; then
    case $status in
    "success")
      echo -e "${GREEN}✓${RESET} $message"
      ;;
    "failure")
      echo -e "${RED}✗${RESET} $message"
      ;;
    "info")
      echo -e "${YELLOW}ℹ${RESET} $message"
      ;;
    "warning")
      echo -e "${YELLOW}⚠${RESET} $message"
      ;;
    esac
  fi
}

check_services() {
  local host=$1
  local service_list=$2
  local quiet_mode=$3
  local short_mode=$4
  local all_services_ok=true

  read -ra requested_services <<<"$service_list"

  if [[ "$short_mode" != "true" ]]; then
    print_status "info" "Checking services on $host..." "$quiet_mode"
  fi

  for service in "${requested_services[@]}"; do
    if ssh $SSH_OPTS "$host" "systemctl list-unit-files $service 2>/dev/null | grep -q $service"; then
      local status
      status=$(ssh $SSH_OPTS "$host" "systemctl is-active $service 2>/dev/null")
      if [[ "$status" != "active" ]]; then
        print_status "warning" "Service $service is not active (status: $status) on $hsot" "$quiet_mode"
        all_services_ok=false
      else
        print_status "success" "Service $service is running on $host" "$quiet_mode"
      fi
    else
      if [[ "$short_mode" != "true" ]]; then
        print_status "info" "Service $service is not installed on $host" "$quiet_mode"
      fi
    fi
  done

  if $all_services_ok; then
    return 0
  else
    return 2
  fi
}

get_service_logs() {
  local host=$1
  local service=$2
  local quiet_mode=$3

  if [[ "$quiet_mode" != "true" ]]; then
    echo "Last 15 lines of logs for $service on $host:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    ssh $SSH_OPTS "$host" "journalctl -u $service -n 15 --no-pager" 2>/dev/null |
      while IFS= read -r line; do
        echo -e "${RED}$line${RESET}"
      done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi
}

control_services() {
  local host=$1
  local service=$2
  local action=$3
  local quiet_mode=$4

  local current_state
  current_state=$(ssh $SSH_OPTS "$host" "systemctl is-active $service 2>/dev/null")

  case "$action" in
  start)
    if [[ "$current_state" == "active" ]]; then
      print_status "info" "Service $service on $host is already active" "$quiet_mode"
      return 0
    fi
    ;;
  stop)
    if [[ "$current_state" != "active" ]]; then
      print_status "info" "Service $service on $host is already stopped (status: $current_state)" "$quiet_mode"
      return 0
    fi
    ;;
  restart) ;;
  esac

  if ! ssh $SSH_OPTS "$host" "systemctl $action $service" 2>/dev/null; then
    print_status "failure" "Failed to $action $service on $host" "$quiet_mode"
    get_service_logs "$host" "$service" "$quiet_mode"
    return 1
  fi

  if [[ "$action" == "stop" ]]; then
    if [[ $(ssh $SSH_OPTS "$host" "systemctl is-active $service 2>/dev/null") != "active" ]]; then
      print_status "success" "Successfully stopped $service on $host" "$quiet_mode"
      return 0
    else
      print_status "failure" "Failed to stop $service on $host" "$quiet_mode"
      get_service_logs "$host" "$service" "$quiet_mode"
      return 1
    fi
  fi

  local counter=0
  local status

  while [ $counter -lt 15 ]; do
    status=$(ssh $SSH_OPTS "$host" "systemctl is-active $service 2>/dev/null")
    if [[ "$status" == "active" ]]; then
      print_status "success" "Successfully $action""ed $service on $host" "$quiet_mode"
      return 0
    fi
    counter=$((counter + 1))
    sleep 1
  done

  print_status "failure" "Service $service failed to start within 15 seconds on $host" "$quiet_mode"
  get_service_logs "$host" "$service" "$quiet_mode"
  return 1
}

ssh_execute() {
  local host=$1
  local quiet_mode=$2
  local short_mode=$3
  local return_status="success"

  local server_type
  server_type=$(echo "$host" | cut -d'_' -f1)

  if [[ "$short_mode" != "true" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_status "info" "Connecting to $host" "$quiet_mode"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  fi

  if ! timeout 10s ssh $SSH_OPTS "$host" "hostname; uptime" >/dev/null 2>&1; then
    print_status "failure" "Failed to connect to $host" "$quiet_mode"
    return 1
  fi

  if ! check_services "$host" "$quiet_mode" "$short_mode"; then
    if [[ "$short_mode" == "true" ]]; then
      print_status "warning" "One or more services are not running correctly on $host" "$quiet_mode"
    fi
    return 2
  fi

  if [[ "$short_mode" != "true" ]]; then
    print_status "success" "Connection to $host successful" "$quiet_mode"
  fi

  return 0
}

list_hosts() {
  local quiet_mode=$1
  if [[ "$quiet_mode" != "true" ]]; then
    print_status "info" "Available hosts:" "false"
    printf '%s\n' "${HOSTS[@]}" | sort | sed 's/^/  /'
  fi
}

print_host_list() {
  local status=$1
  local quiet_mode=$2
  shift 2
  local -a hosts=("$@")

  if [[ "$quiet_mode" != "true" ]]; then
    if [ ${#hosts[@]} -eq 0 ]; then
      echo "  None"
    else
      IFS=$'\n' sorted_hosts=($(sort <<<"${hosts[*]}"))
      unset IFS

      local host_list=$(printf "%s, " "${sorted_hosts[@]}")
      host_list=${host_list%, }

      print_status "$status" "$host_list" "false"
    fi
  fi
}

handle_host_services() {
  local host=$1
  local server_type=$2

  if ! timeout 10s ssh $SSH_OPTS "$host" "hostname; uptime" >/dev/null 2>&1; then
    print_status "failure" "Failed to connect to $host" "$QUIET_MODE"
    return 1
  fi

  case "$ACTION" in
  status)
    if [[ -z "$SERVICES" ]]; then
      SERVICES="all"
    fi
    local has_services=false
    local service_ok=true
    IFS=',' read -ra SERVICE_LIST <<<"$SERVICES"
    for service in "${SERVICE_LIST[@]}"; do
      case $service in
      "all")
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files mariadb.service dbworker.service 2>/dev/null | grep -q '\.service'"; then
          has_services=true
          check_services "$host" "mariadb.service dbworker.service" "$QUIET_MODE" "$SHORT_MODE" || service_ok=false
        fi
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files backend.service 2>/dev/null | grep -q '\.service'"; then
          has_services=true
          check_services "$host" "backend.service" "$QUIET_MODE" "$SHORT_MODE" || service_ok=false
        fi
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files node_server.service middleware.service 2>/dev/null | grep -q '\.service'"; then
          has_services=true
          check_services "$host" "node_server.service middleware.service" "$QUIET_MODE" "$SHORT_MODE" || service_ok=false
        fi
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files rabbitmq-server.service 2>/dev/null | grep -q '\.service'"; then
          has_services=true
          check_services "$host" "rabbitmq-server.service" "$QUIET_MODE" "$SHORT_MODE" || service_ok=false
        fi
        ;;
      "database")
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files mariadb.service dbworker.service 2>/dev/null | grep -q '\.service'"; then
          has_services=true
          check_services "$host" "mariadb.service dbworker.service" "$QUIET_MODE" "$SHORT_MODE" || service_ok=false
        fi
        ;;
      "backend")
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files backend.service 2>/dev/null | grep -q '\.service'"; then
          has_services=true
          check_services "$host" "backend.service" "$QUIET_MODE" "$SHORT_MODE" || service_ok=false
        fi
        ;;
      "frontend")
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files node_server.service middleware.service 2>/dev/null | grep -q '\.service'"; then
          has_services=true
          check_services "$host" "node_server.service middleware.service" "$QUIET_MODE" "$SHORT_MODE" || service_ok=false
        fi
        ;;
      "communication")
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files rabbitmq-server.service 2>/dev/null | grep -q '\.service'"; then
          has_services=true
          check_services "$host" "rabbitmq-server.service" "$QUIET_MODE" "$SHORT_MODE" || service_ok=false
        fi
        ;;
      esac
    done

    if ! $has_services; then
      if [[ "$SHORT_MODE" != "true" ]]; then
        print_status "info" "No monitored services installed on $host" "$QUIET_MODE"
      fi
      return 255
    fi
    if $service_ok; then
      return 0
    else
      return 2
    fi

    ssh_execute "$host" "$QUIET_MODE" "$SHORT_MODE"
    return $?
    ;;
  start | stop | restart)
    if [[ "$SHORT_MODE" != "true" ]]; then
      print_status "info" "Performing $ACTION on services for $host" "$QUIET_MODE"
    fi

    local service_status=0
    if [[ -z "$SERVICES" ]]; then
      SERVICES="all"
    fi
    IFS=',' read -ra SERVICE_LIST <<<"$SERVICES"
    for service in "${SERVICE_LIST[@]}"; do
      case $service in
      "all")
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files dbwoeker.service 2>/dev/null | grep -q '\.service'"; then
          control_services "$host" "mariadb.service" "$ACTION" "$QUIET_MODE" || service_status=1
          control_services "$host" "dbworker.service" "$ACTION" "$QUIET_MODE" || service_status=1
        fi
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files backend.service 2>/dev/null | grep -q '\.service'"; then
          control_services "$host" "backend.service" "$ACTION" "$QUIET_MODE" || service_status=1
        fi
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files node_server.service 2>/dev/null | grep -q '\.service'"; then
          control_services "$host" "node_server.service" "$ACTION" "$QUIET_MODE" || service_status=1
          control_services "$host" "middleware.service" "$ACTION" "$QUIET_MODE" || service_status=1
        fi
        if ssh $SSH_OPTS "$host" "systemctl list-unit-files rabbitmq-server.service 2>/dev/null | grep -q '\.service'"; then
          control_services "$host" "rabbitmq-server.service" "$ACTION" "$QUIET_MODE" || service_status=1
        fi
        ;;
      "database")
        control_services "$host" "mariadb.service" "$ACTION" "$QUIET_MODE" || service_status=1
        control_services "$host" "dbworker.service" "$ACTION" "$QUIET_MODE" || service_status=1
        ;;
      "backend")
        control_services "$host" "backend.service" "$ACTION" "$QUIET_MODE" || service_status=1
        ;;
      "frontend")
        control_services "$host" "node_server.service" "$ACTION" "$QUIET_MODE" || service_status=1
        control_services "$host" "middleware.service" "$ACTION" "$QUIET_MODE" || service_status=1
        ;;
      "communication")
        control_services "$host" "rabbitmq-server.service" "$ACTION" "$QUIET_MODE" || service_status=1
        ;;
      esac
    done
    ;;
  setup)
    if [[ -z "$SERVICES" ]]; then
      SERVICES="all"
    fi
    IFS=',' read -ra SERVICE_LIST <<<"$SERVICES"
    local setup_status=0
    for service in "${SERVICE_LIST[@]}"; do
      case $service in
      "all") setup_services "$host" "frontend backend database communication" "$QUIET_MODE" || setup_status=1 ;;
      "frontend") setup_frontend_service "$host" "$QUIET_MODE" || setup_status=1 ;;
      "backend") setup_backend_service "$host" "$QUIET_MODE" || setup_status=1 ;;
      "database") setup_database_service "$host" "$QUIET_MODE" || setup_status=1 ;;
      "communication") setup_communication_service "$host" "$QUIET_MODE" || setup_status=1 ;;
      esac
    done
    return $setup_status
    ;;
  esac
}

setup_repository() {
  local host=$1
  local quiet_mode=$2

  print_status "info" "Setting up repository on $host..." "$quiet_mode"

  if ! ssh $SSH_OPTS "$host" "
    if [ ! -d $REPO_PATH ]; then
      git clone --branch $REPO_BRANCH $REPO_URL $REPO_PATH
    else 
      cd $REPO_PATH
      git fetch
      git reset --hard origin/$REPO_BRANCH
    fi
  "; then
    print_status "failure" "Failed to setup repository on $host" "$quiet_mode"
    return 1
  fi

  print_status "success" "Repository setup completed on $host" "$quiet_mode"
  return 0
}

install_packages() {
  local quiet_mode=$1
  shift
  local packages=("$@")

  print_status "info" "Updating package lists..." "$quiet_mode"
  if ! apt-get update -y; then
    print_status "failure" "Failed to update package lists" "$quiet_mode"
    return 1
  fi

  print_status "info" "Upgrading packages..." "$quiet_mode"
  if ! apt-get upgrade -y; then
    print_status "failure" "Failed to upgrade packages" "$quiet_mode"
    return 1
  fi

  print_status "info" "Installing packages: ${packages[*]}" "$quiet_mode"
  if ! apt-get install -y --fix-missing "${packages[@]}"; then
    print_status "failure" "Failed to install packages" "$quiet_mode"
    return 1
  fi

  print_status "success" "Successfully installed all packages" "$quiet_mode"
  return 0
}

# =============================================================================
# Setup Functions
# =============================================================================

setup_frontend_service() { # NOTE: This doesn't reflect the load balancing / reverse proxy setup that Shak is doing
  local host=$1
  local quiet_mode=$2

  if ! setup_repository "$host" "$quiet_mode"; then
    return 1
  fi

  print_status "info" "Setting up frontend services on $host..." "$quiet_mode"

  if ! ssh $SSH_OPTS "$host" "
    cd $REPO_PATH/frontend
    npm install
    npm run build

    if [ -f /etc/systemd/system/node_server.service ]; then
      systemctl stop node_server.service
      rm /etc/systemd/system/node_server.service
      systemctl daemon-reload
    fi
    if [ -f /etc/systemd/system/middleware.service ]; then
      systemctl stop middleware.service
      rm /etc/systemd/system/middleware.service
      systemctl daemon-reload
    fi

    systemctl link $REPO_PATH/frontend/node_server.service
    systemctl link $REPO_PATH/frontend/middleware.service
    systemctl daemon-reload
    systemctl enable --now node_server.service middleware.service
  "; then
    print_status "failure" "Failed to setup frontend services on $host" "$quiet_mode"
    return 1
  fi

  print_status "success" "Frontend setup completed on $host" "$quiet_mode"
  return 0
}

setup_backend_service() {
  local host=$1
  local quiet_mode=$2

  if ! setup_repository "$host" "$quiet_mode"; then
    return 1
  fi

  print_status "info" "Setting up backend services on $host..." "$quiet_mode"

  if ! ssh $SSH_OPTS "$host" "
    cd $REPO_PATH/backend
    pip3 install pika aio-pika

    if [ -f /etc/systemd/system/backend.service ]; then
      systemctl stop backend.service
      rm /etc/systemd/system/backend.service
      systemctl daemon-reload
    fi

    systemctl link $REPO_PATH/backend/backend.service
    systemctl daemon-reload
    systemctl enable --now backend.service
  "; then
    print_status "failure" "Failed to setup backend services on $host" "$quiet_mode"
    return 1
  fi

  print_status "success" "Backend setup completed on $host" "$quiet_mode"
  return 0
}

setup_database_service() {
  local host=$1
  local quiet_mode=$2
  local primary_node

  if ! setup_repository "$host" "$quiet_mode"; then
    return 1
  fi

  print_status "info" "Setting up database services on $host..." "$quiet_mode"

  find_primary_node() {
    for h in "${HOSTS[@]}"; do
      [[ "$h" != database_* ]] && continue
      if timeout 5 ssh $SSH_OPTS "$h" "
        systemctl is-active mariadb > /dev/null 2>&1 &&
        mariadb -N -e 'show status like \"wsrep_cluster_size\"' | grep -q '[2-9]'
      " 2>/dev/null; then
        echo "$h"
        return 0
      fi
    done
    echo ""
    return 1
  }

  galera_config() {
    local target=$1
    local is_first=$2
    local primary=$3

    ssh $SSH_OPTS "$target" "
      cd $REPO_PATH/database
      
      CLUSTER_MEMBERS=\$(for i in {0..3}; do tailscale ip database-\$i 2>/dev/null | head -n1 done | grep . | paste -sd,)

      cat > galera.cnf.tmp <<EOF
      [galera]
      wsrep_on                 = ON
      wsrep_cluster_name       = \"AppliCare Galera Cluster\"
      wsrep_node_name          = \"\$(hostname)\"
      wsrep_node_address       = \"\$(tailscale ip | head -n1)\"
      binlog_format            = row
      default_storage_engine   = InnoDB
      innodb_autoinc_lock_mode = 2

      bind-address = 0.0.0.0
      wsrep_slave_threads      = 1
      wsrep_sst_method         = rsync

      $(if [[ "$is_first" == "true" ]]; then
      echo "wsrep_cluster_address    = gcomm://"
      echo "wsrep_new_cluster       = true"
    else
      echo "wsrep_cluster_address    = gcomm://\$CLUSTER_MEMBERS"
    fi)

      wsrep_provider_options   = \"gmcast.listen_addr=tcp://0.0.0.0:4567;ist.recv_addr=\$(tailscale ip | head -n1)\"
      wsrep_retry_autocommit   = 3
      EOF

      mkdir -p /etc/mysql/mariadb.conf.d/
      mv galera.cnf.tmp /etc/mysql/mariadb.conf.d/galera.cnf
    "
    return $?
  }

  primary_node=$(find_primary_node)
  if [[ -z "$primary_node" ]]; then
    print_status "info" "Setting up first database node on $host..." "$quiet_mode"

    if ! ssh $SSH_OPTS "$host" "
      cd $REPO_PATH/database
      
      ufw allow 3306,4567,4568,4444/tcp
      ufw allow 4567/udp
      ufw enable && ufw reload

      systemctl stop mariadb
      if [ -f /etc/systemd/system/dbworker.service ]; then
        systemctl stop dbworker.service
        rm /etc/systemd/system/dbworker.service
      fi

      rm -rf /var/lib/mysql/*
      cp my.cnf /etc/mysql/my.cnf
    "; then
      print_status "failure" "Failed initial database setup on $host" "$quiet_mode"
      return 1
    fi

    if ! galera_config "$host" "true" ""; then
      print_status "failure" "Failed to generate Galera config on $host" "$quiet_mode"
      return 1
    fi

    if ! ssh $SSH_OPTS "$host" "
      galera_new_cluster
      if [ -f $REPO_PATH/database/applicare.sql ]; then
        mariadb -u root < $REPO_PATH/database/applicare.sql
      fi
    "; then
      print_status "failure" "Failed to bootstrap Galera cluster on $host" "$quiet_mode"
      return 1
    fi
  else
    print_status "info" "Joining existing Galera cluster via $primary_node..." "$quiet_mode"

    if ! ssh $SSH_OPTS "$host" "
      cd $REPO_PATH/database
      
      ufw allow 3306,4567,4568,4444/tcp
      ufw allow 4567/udp
      ufw enable && ufw reload

      systemctl stop mariadb
      rm -rf /var/lib/mysql/*
      cp my.cnf /etc/mysql/my.cnf
    "; then
      print_status "failure" "Failed initial database setup on $host" "$quiet_mode"
      return 1
    fi

    if ! galera_config "$host" "false" "$primary_node"; then
      print_status "failure" "Failed to generate Galera config on $host" "$quiet_mode"
      return 1
    fi

    if ! ssh $SSH_OPTS "$host" "systemctl start mariadb"; then
      print_status "failure" "Failed to join Galera cluster on $host" "$quiet_mode"
      return 1
    fi
  fi

  if ! ssh $SSH_OPTS "$host" "
    systemctl link $REPO_PATH/database/dbworker.service
    systemctl daemon-reload
    systemctl enable --now mariadb dbworker.service
  "; then
    print_status "failure" "Failed to setup database services on $host" "$quiet_mode"
    return 1
  fi

  print_status "success" "Database setup completed on $host" "$quiet_mode"
  return 0
}

setup_communication_service() { # NOTE: This doesn't reflect the actual RMQ clustering setup that Yashi is doing
  local host=$1
  local quiet_mode=$2

  print_status "info" "Setting up communication services on $host..." "$quiet_mode"

  setup_base_node() {
    local target=$1
    ssh $SSH_OPTS "$target" "
      ufw allow 5672/tcp
      ufw allow 15672/tcp
      ufw allow 25672/tcp
      ufw allow 4369/tcp
      ufw allow ssh
      ufw enable && ufw reload

      mkdir -p /etc/rabbitmq
      cat > /etc/rabbitmq/rabbitmq.conf <<EOF
      listeners.tcp.default = 5672
      management.tcp.port = 15672
      
      vm_memory_high_watermark.relative = 0.7
      disk_free_limit.relative = 2.0
      
      cluster_partition_handling = ignore
      cluster_keepalive_interval = 10000
      EOF

      chown -R rabbitmq:rabbitmq /etc/rabbitmq
      chmod -R 640 /etc/rabbitmq/*

      systemctl stop rabbitmq-server
      rm -rf /var/lib/rabbitmq/*
      systemctl start rabbitmq-server
    "
    return $?
  }

  setup_primary_node() {
    local target=$1

    setup_base_node "$target" || return 1

    ssh $SSH_OPTS "$target" "
      rabbitmq-plugins enable rabbitmq_management
      rabbitmqctl add_user admin RBMQ 
      rabbitmqctl set_user_tags admin administrator
      rabbitmqctl set_permissions -p / admin '.*' '.*' '.*'
      
      rabbitmqctl delete_user guest
      
      rabbitmqctl set_policy ha-all '.*' '{\"ha-mode\":\"all\", \"ha-sync-mode\":\"automatic\"}'
      
      rabbitmq-plugins enable rabbitmq_shovel
      rabbitmq-plugins enable rabbitmq_federation
    "
    return $?
  }

  join_cluster() {
    local target=$1
    local primary=$2

    setup_base_node "$target" || return 1

    scp $SSH_OPTS "$primary":/var/lib/rabbitmq/.erlang.cookie "$target":/var/lib/rabbitmq/ &&
      ssh $SSH_OPTS "$target" "
      chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
      chmod 400 /var/lib/rabbitmq/.erlang.cookie
      
      systemctl restart rabbitmq-server
      rabbitmqctl stop_app
      rabbitmqctl reset
      rabbitmqctl join_cluster rabbit@$primary
      rabbitmqctl start_app

      rabbitmq-plugins enable rabbitmq_management
      rabbitmq-plugins enable rabbitmq_shovel
      rabbitmq-plugins enable rabbitmq_federation
    "
    return $?
  }

  find_primary_node() {
    for h in "${HOSTS[@]}"; do
      [[ "$h" != communication_* ]] && continue
      if timeout 5 ssh $SSH_OPTS "$h" "
        systemctl is-active rabbitmq-server > /dev/null 2>&1 &&
        rabbitmqctl cluster_status | grep -q 'Running Nodes'
      " 2>/dev/null; then
        echo "$h"
        return 0
      fi
    done
    echo ""
    return 1
  }

  if ! ssh $SSH_OPTS "$host" "$(typeset -f install_packages); install_packages ${COMMUNICATION_PACKAGES[*]}"; then
    print_status "failure" "Failed to install communication packages on $host" "$quiet_mode"
    return 1
  fi

  local primary_node
  primary_node=$(find_primary_node)

  if [[ -z "$primary_node" ]]; then
    print_status "info" "Setting up first RabbitMQ node on $host..." "$quiet_mode"
    if ! setup_primary_node "$host"; then
      print_status "failure" "Failed to setup first RabbitMQ node on $host" "$quiet_mode"
      return 1
    fi
  else
    print_status "info" "Joining existing RabbitMQ cluster with primary node $primary_node..." "$quiet_mode"
    if ! join_cluster "$host" "$primary_node"; then
      print_status "failure" "Failed to join RabbitMQ cluster on $host" "$quiet_mode"
      return 1
    fi
  fi

  print_status "success" "Communication setup completed on $host" "$quiet_mode"
  return 0
}

setup_services() {
  local host=$1
  local services=$2
  local quiet_mode=$3

  if ! setup_repository "$host" "$quiet_mode"; then
    return 1
  fi

  for service in $services; do
    case $service in
    "frontend")
      setup_frontend_service "$host" "$quiet_mode"
      ;;
    "backend")
      setup_backend_service "$host" "$quiet_mode"
      ;;
    "database")
      setup_database_service "$host" "$quiet_mode"
      ;;
    "communication")
      setup_communication_service "$host" "$quiet_mode"
      ;;
    esac
  done
}

# =============================================================================
# Main Function
# =============================================================================

main() {
  local TYPE=""
  local NUMBER=""
  local QUIET_MODE="false"
  local SHORT_MODE="false"
  local ACTION="status"
  local LIST_MODE=""
  local SERVICES="all" # Set default value to "all"

  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -l, --list <TYPE>       List hosts by status type"
      echo "                          (all|up|active)"
      echo "  -N, --name <NAME>       Connect only to hosts of specified name-type"
      echo "                          (frontend|backend|database|communication)"
      echo "  -n, --number <NUMBER>   Connect only to hosts with specified number (0-3)"
      echo "  -a, --action <ACTION>   Perform the following action on each host (default 'status')"
      echo "                          (status|start|stop|restart)"
      echo "  -s, --short             Short mode - don't show the status of each VMs' services"
      echo "  -q, --quiet             Quiet mode - only show final summary"
      echo "  --services <SERVICES>   Specify services to interact with as a comma-separated list (i.e. \"frontend,backend\")"
      echo "                          (frontend|backend|database|communication|all) -- default is 'all'"
      echo "  -h, --help              Show this help message"
      exit 0
      ;;
    -l | --list)
      LIST_MODE="$2"
      shift 2
      ;;
    -N | --name)
      TYPE="$2"
      shift 2
      ;;
    -n | --number)
      NUMBER="$2"
      shift 2
      ;;
    -a | --action)
      case "$2" in
      status | start | stop | restart | setup)
        ACTION="$2"
        ;;
      *)
        print_status "failure" "Invalid action: $2. Must be one of: status, start, stop, restart" "false"
        exit 1
        ;;
      esac
      shift 2
      ;;
    -s | --short)
      SHORT_MODE="true"
      shift
      ;;
    -q | --quiet)
      QUIET_MODE="true"
      SHORT_MODE="true"
      shift
      ;;
    --services)
      SERVICES="$2"
      shift 2
      ;;
    *)
      shift
      ;;
    esac
  done

  if [[ -n "$LIST_MODE" ]]; then
    case "$LIST_MODE" in
    all)
      list_hosts "$QUIET_MODE"
      ;;
    up)
      local -a up_hosts=()
      for host in "${HOSTS[@]}"; do
        if timeout 10s ssh $SSH_OPTS "$host" "hostname" >/dev/null 2>&1; then
          up_hosts+=("$host")
        fi
      done
      print_status "info" "Reachable hosts:" "$QUIET_MODE"
      print_host_list "success" "$QUIET_MODE" "${up_hosts[@]}"
      ;;
    active)
      local -a active_hosts=()
      for host in "${HOSTS[@]}"; do
        if ssh_execute "$host" "true" "true" >/dev/null 2>&1; then
          active_hosts+=("$host")
        fi
      done
      print_status "info" "Hosts with all services active:" "$QUIET_MODE"
      print_host_list "success" "$QUIET_MODE" "${active_hosts[@]}"
      ;;
    *)
      print_status "failure" "Invalid list type: $LIST_MODE. Must be one of: all, up, active" "false"
      exit 1
      ;;
    esac
    exit 0
  fi

  local -a success_hosts=()
  local -a warning_hosts=()
  local -a failed_hosts=()

  for host in "${HOSTS[@]}"; do
    if [[ -n "$TYPE" && "$host" != "${TYPE}_"* ]]; then
      continue
    fi
    if [[ -n "$NUMBER" && "$host" != *"_${NUMBER}" ]]; then
      continue
    fi

    server_type=$(echo "$host" | cut -d'_' -f1)
    handle_host_services "$host" "$server_type"

    case $? in
    0)
      success_hosts+=("$host")
      ;;
    1)
      failed_hosts+=("$host")
      ;;
    2)
      warning_hosts+=("$host")
      ;;
    255) ;;
    esac

    if [[ "$SHORT_MODE" != "true" ]]; then
      echo
    fi
  done

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Summary:"
  print_status "success" "Successful connections: ${#success_hosts[@]}" "false"
  print_status "warning" "Hosts with warnings: ${#warning_hosts[@]}" "false"
  print_status "failure" "Failed connections: ${#failed_hosts[@]}" "false"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ "$QUIET_MODE" != "true" ]]; then
    echo "Successful hosts:"
    print_host_list "success" "$QUIET_MODE" "${success_hosts[@]}"
    echo
    echo "Hosts with service warnings:"
    print_host_list "warning" "$QUIET_MODE" "${warning_hosts[@]}"
    echo
    echo "Failed hosts:"
    print_host_list "failure" "$QUIET_MODE" "${failed_hosts[@]}"
  fi
}

main "$@"
exit 0

#TODO: Add monitoring for the cluster status
#RODO: Add a 'praseable' mode for the script to output in JSON
#TODO: Add a 'Heartbeat' option to check the status of the services every (1) minute
