#!/bin/bash


echo "=== Raw tailscale output ==="
tailscale status
echo

echo "=== Breaking down pattern matching ==="
tailscale status | while read -r line; do
  if [[ "$line" =~ ^100\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    hostname=$(echo "$line" | awk '{print $2}')
    if [[ "$hostname" =~ ^(frontend|backend|database|communication)-[0-9]+$ ]]; then
      echo "Found service host: $hostname"
    fi
  fi
done

echo
echo "=== Final filtered list ==="
mapfile -t HOSTS < <(tailscale status | \
  awk '$2 ~ /^(frontend|backend|database|communication)-[0-9]+$/ {print $2}' | \
  sort)

echo "Number of hosts found: ${#HOSTS[@]}"
printf '%s\n' "${HOSTS[@]}"
