#!/bin/bash
IP_ADDRESS=$(hostname -I | awk '{print $1}')
export IP_ADDRESS
export JUDGEHOST_PASSWORD=GIAchaw2fUOkIkTI+AHbMh9NVmXbiMJc
export DOMSERVER_MAIN_IP='10.0.2.95'
docker container rm -f $(docker container ls -q)
docker compose -f judgehost.yml up -d