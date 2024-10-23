#!/bin/bash

export DB_HOST=database-icpc.cpas8kasitfl.us-east-1.rds.amazonaws.com
export DB_ROOT_PASSWORD=QUSa5AUOjsXFYbRN2FVL
export DJ_DB=domjudge
export DJ_DB_USER=domjudge
export DJ_DB_PASSWORD=djpw
docker container rm -f $(docker container ls -q)
docker compose -f domserver.yml up -d