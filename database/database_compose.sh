#!/bin/bash

# Initial setup

ufw allow ssh; ufw enable
sudo apt update -y && sudo apt upgrade -y
curl -fsSL https://www.tailscale.com/install.sh | sh

# Install / setup MariaDB

apt_packages = (
  mariadb-server 
  mariadb-clien
  # Technically the rest here are for Galera not strictly for MariaDB...
  galera-4
  rsync
  mariadb-plugin-provider-bzip2
  mariadb-plugin-provider-lz4
  mariadb-plugin-provider-lzma
  mariadb-plugin-provider-lzo
  mariadb-plugin-provider-snappy
  # haproxy
)

for package in "${apt_packages[@]}"; do
  apt install "$package"
done

systemctl enable mariadb
systemctl start mariadb

mariadb -u root < applicare.sql
if [ $? -ne 0 ]; then
    echo "Failed to load dump file"
fi

# Configure Galera / Clusters

mkdir -p /etc/mysql/mariadb.conf.d/

systemctl stop mariadb
rm -rf /var/lib/mysql/*

cp my.cnf /etc/mysql/my.cnf

eval "cat <<EOF
$(cat galera.cnf)
EOF" > /etc/mysql/mariadb.conf.d/galera.cnf

ufw allow 3306,4567,4568,4444/tcp
ufw allow 4567/udp
ufw reload

systemctl start mariadb

# Install / setup DBWorker.py

export py_packages=(
  pika
  mysql.connector
)

if ! command -v "python3" &>/dev/null; then
  apt install python3-full python3-pip -y
fi

for package in "${py_packages[@]}"; do
  apt install -y "python3-$package"
done

if [ -f /etc/systemd/system/dbworker.service ]; then
  rm /etc/systemd/system/dbworker.service
  systemctl daemon-reload
fi

systemctl link ./dbworker.service
systemctl daemon-reload
systemctl start dbworker.service
systemctl enable dbworker.service
