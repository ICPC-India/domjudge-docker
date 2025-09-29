#!/bin/bash
# Helper script to extract JUDGEHOST_PASSWORD from domserver logs and update .env file
# Usage: ./extract_judgehost_password.sh [dev|prod] (default: dev)

#!/bin/bash
# Helper script to extract JUDGEHOST_PASSWORD from domserver logs and update .env file
# Usage: ./extract_judgehost_password.sh [dev|prod] (default: dev)

set -euo pipefail

ENV=${1:-dev}
ENV_FILE=".env.$ENV"

# Compose args mirror Makefile behavior
if [ "$ENV" = "prod" ]; then
  COMPOSE_ARGS="-f docker-compose.dev.yml -f docker-compose.yml"
else
  COMPOSE_ARGS="-f docker-compose.dev.yml"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo ".env file $ENV_FILE not found!" >&2
  exit 1
fi

echo "Extracting JUDGEHOST_PASSWORD from domserver logs (env=$ENV)..."

# Try to extract lines like:
#   Initial judgehost password is PPiQn+Hh...
#   ...judgehost password: <password>
# Use case-insensitive search and capture the last token on the matching line
PASSWORD=$(docker compose --env-file "$ENV_FILE" $COMPOSE_ARGS logs domserver 2>/dev/null \
  | grep -Eio 'judgehost password (is|:)[[:space:]]*\S+' \
  | awk '{print $NF}' \
  | tail -n1 || true)

if [ -z "$PASSWORD" ]; then
  echo "Could not find judgehost password in domserver logs." >&2
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
