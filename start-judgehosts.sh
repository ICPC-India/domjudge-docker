#!/bin/bash

num_judgehosts=${1:-1}  # Default to 1 if no argument is provided

for i in $(seq 1 $num_judgehosts)
do
  DAEMON_ID=$i docker-compose -f judgehost.yml up -d --no-recreate --scale judgehost=1
done