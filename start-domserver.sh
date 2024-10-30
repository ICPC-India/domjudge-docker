#!/bin/bash

export DB_HOST=icpc-rds.cpas8kasitfl.us-east-1.rds.amazonaws.com
export DB_ROOT_PASSWORD=mOf2QrnI5tS5y0wRzv81
export DJ_DB=domjudge
export DJ_DB_USER=domjudge
export DJ_DB_PASSWORD=djpw

# Remove all running containers
docker container rm -f $(docker container ls -q)

# Check for command line argument
if [ "$2" == "redis" ]; then
    # Start Redis and DOMserver with Redis configuration
    FPM_MAX_CHILDREN=$1 docker compose -f domserver-redis.yml up -d
    docker compose -f redis.yml up -d
else
    # Start regular DOMserver setup
    FPM_MAX_CHILDREN=$1 docker compose -f domserver.yml up -d
fi
