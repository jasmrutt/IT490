#!/bin/bash

if systemctl is-active backend.service >/dev/null 2>&1; then
    echo "up"
    exit 0
else
    echo "down"
    exit 1
fi
