#!/bin/bash
# Helper script to extract JUDGEHOST_PASSWORD from domserver logs and update .env file
# Usage: ./extract_judgehost_password.sh [dev|prod] (default: dev)

ENV=${1:-dev}
ENV_FILE=".env.$ENV"
COMPOSE_FILE="config/docker-compose.$ENV.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Compose file $COMPOSE_FILE not found!"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo ".env file $ENV_FILE not found!"
  exit 1
fi

# Extract password from domserver logs
echo "Extracting JUDGEHOST_PASSWORD from domserver logs..."
PASSWORD=$(docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs domserver | grep -Eo 'judgehost password: [^ ]+' | awk '{print $3}' | tail -1)

if [ -z "$PASSWORD" ]; then
  echo "Could not find judgehost password in domserver logs."
  exit 1
fi

echo "Found JUDGEHOST_PASSWORD: $PASSWORD"

# Update or insert JUDGEHOST_PASSWORD in .env file
if grep -q '^JUDGEHOST_PASSWORD=' "$ENV_FILE"; then
  sed -i "s/^JUDGEHOST_PASSWORD=.*/JUDGEHOST_PASSWORD=$PASSWORD/" "$ENV_FILE"
else
  echo "JUDGEHOST_PASSWORD=$PASSWORD" >> "$ENV_FILE"
fi

echo "Updated $ENV_FILE with JUDGEHOST_PASSWORD."
