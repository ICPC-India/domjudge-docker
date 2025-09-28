#!/bin/bash
IP_ADDRESS=$(hostname -I | awk '{print $1}')
IP_ADDRESS=$(echo "$IP_ADDRESS" | sed 's/\./-/g')
export IP_ADDRESS
export JUDGEHOST_PASSWORD=iejOtEA7kgzt5wMpa8CsnXh5eofTea/W
export DOMSERVER_MAIN_IP='internal-ICPC-ALB-JUDGING-219721622.us-east-1.elb.amazonaws.com'
docker container rm -f $(docker container ls -q)
docker compose -f judgehost.yml up -d
