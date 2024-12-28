#!/bin/bash
clear
trap 'clear; exit 1' INT;
while true; do
  echo -en "\033[0;0H"
 
  QUEUE_TABLE=$(rabbitmqctl -q list_queues state name consumers messages_ready messages_unacknowledged --formatter pretty_table 2>/dev/null | grep -v '^\[[0-9]')
  NODE_LIST=$(rabbitmq-diagnostics -q cluster_status 2>/dev/null | grep -A4 -i "running" | tail -n3 | sed 's/^[[:space:]]*//')
 
  MAX_LENGTH=$(echo "$NODE_LIST" | awk '{ print length($0) }' | sort -nr | head -1)
  WIDTH=$((MAX_LENGTH + 4))
 
  TOP_LINE="   ┌$(printf '─%.0s' $(seq 1 $WIDTH))┐"
  MID_LINE="   ├$(printf '─%.0s' $(seq 1 $WIDTH))┤"
  BOT_LINE="   └$(printf '─%.0s' $(seq 1 $WIDTH))┘"
 
  paste <(echo "$QUEUE_TABLE") <(
    echo "$TOP_LINE"
    echo "   │ Running Nodes$(printf ' %.0s' $(seq 1 $((WIDTH - 14))))│"
    echo "$MID_LINE"
    echo "$NODE_LIST" | awk -v w=$WIDTH '{printf "   │ %s%*s│\n", $0, w-length($0)-1, " "}'
    echo "$BOT_LINE"
  )
done
