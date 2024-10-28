#!/bin/bash

export DB_HOST=database-icpc.cpas8kasitfl.us-east-1.rds.amazonaws.com
export DB_ROOT_PASSWORD=QUSa5AUOjsXFYbRN2FVL
export DJ_DB=domjudge
export DJ_DB_USER=domjudge
export DJ_DB_PASSWORD=djpw

# Remove all running containers
docker container rm -f $(docker container ls -q)

# Check for command line argument
if [ "$1" == "redis" ]; then
    # Start Redis and DOMserver with Redis configuration
    docker compose -f domserver-redis.yml up -d
    docker compose -f redis.yml up -d
else
    # Start regular DOMserver setup
    docker compose -f domserver.yml up -d
fi
