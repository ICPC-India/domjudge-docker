#!/bin/bash
IP_ADDRESS=$(hostname -I | awk '{print $1}')
DAEMON_ID=$(echo $IP_ADDRESS | awk -F. '{print $4}')
export DAEMON_ID
export JUDGEHOST_PASSWORD=GIAchaw2fUOkIkTI+AHbMh9NVmXbiMJc
export DOMSERVER_MAIN_IP='10.0.2.95'
docker compose -f judgehost.yml down
docker compose -f judgehost.yml up -d