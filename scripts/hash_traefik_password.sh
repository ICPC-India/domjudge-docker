#!/usr/bin/env bash
set -euo pipefail

# hash_traefik_password.sh
# Generate TRAEFIK_HASHED_PASSWORD from TRAEFIK_PLAINTEXT_PASSWORD in .env file
# Usage: ./scripts/hash_traefik_password.sh [env]
#   env defaults to 'dev' and will operate on .env.dev (or pass 'prod' for .env.prod)

ENV=${1:-dev}
ENV_FILE=".env.$ENV"

if [ ! -f "$ENV_FILE" ]; then
  echo "Environment file $ENV_FILE not found." >&2
  exit 1
fi

echo "Backing up $ENV_FILE -> ${ENV_FILE}.bak.$(date +%Y%m%d%H%M%S)"
cp "$ENV_FILE" "${ENV_FILE}.bak.$(date +%Y%m%d%H%M%S)"

# Read plaintext password
PLAINTEXT=$(grep -E '^TRAEFIK_PLAINTEXT_PASSWORD=' "$ENV_FILE" | sed -E 's/^TRAEFIK_PLAINTEXT_PASSWORD=//') || true

if [ -z "$PLAINTEXT" ]; then
  echo "TRAEFIK_PLAINTEXT_PASSWORD not found or empty in $ENV_FILE" >&2
  exit 1
fi

echo "Generating hashed password with openssl..."
HASHED=$(openssl passwd -apr1 "$PLAINTEXT")

if grep -q '^TRAEFIK_HASHED_PASSWORD=' "$ENV_FILE"; then
  sed -i "s#^TRAEFIK_HASHED_PASSWORD=.*#TRAEFIK_HASHED_PASSWORD=$HASHED#" "$ENV_FILE"
else
  echo "TRAEFIK_HASHED_PASSWORD='$HASHED'" >> "$ENV_FILE"
fi

echo "Updated $ENV_FILE with TRAEFIK_HASHED_PASSWORD."
