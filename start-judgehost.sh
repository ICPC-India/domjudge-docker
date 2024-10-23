#!/bin/bash
IP_ADDRESS=$(hostname -I | awk '{print $1}')
DAEMON_ID=$(echo $IP_ADDRESS | awk -F. '{print $4}')
export DAEMON_ID
docker compose -f judgehost.yml up -d