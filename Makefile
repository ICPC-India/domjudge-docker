# ===========================
# DOMjudge Docker Deployment
# ===========================

# Default environment (can be overridden: make up ENV=prod)
ENV ?= dev

# Environment file (per-ENV)
ENV_FILE := .env.$(ENV)

# Compose file selection
ifeq ($(ENV),prod)
COMPOSE_FILE := -f docker-compose.dev.yml -f docker-compose.yml
else
COMPOSE_FILE := -f docker-compose.dev.yml
endif

# Docker Compose command (use 'docker compose' for v2+)
DC := docker compose

# Ensure env file exists
ifeq (,$(wildcard $(ENV_FILE)))
$(error Environment file '$(ENV_FILE)' not found!)
endif

# ===========================
# Targets
# ===========================

.PHONY: check-docker up down restart logs ps env scale \
        extract-password hash-password help

# ---- Setup & Utilities ----

check-docker:
	@echo "🔍 Checking Docker installation..."
	@bash scripts/checkAndInstallDocker.sh || { echo >&2 "❌ scripts/checkAndInstallDocker.sh failed."; exit 1; }

hash-password:
	@echo "🔑 Generating TRAEFIK_HASHED_PASSWORD from TRAEFIK_PLAINTEXT_PASSWORD in $(ENV_FILE)..."
	PLAINTEXT=$$(grep '^TRAEFIK_PLAINTEXT_PASSWORD=' $(ENV_FILE) | cut -d'=' -f2-); \
	if [ -z "$$PLAINTEXT" ]; then \
	  echo "❌ TRAEFIK_PLAINTEXT_PASSWORD not set in $(ENV_FILE)"; exit 1; \
	fi; \
	HASHED=$$(openssl passwd -apr1 "$$PLAINTEXT"); \
	if grep -q '^TRAEFIK_HASHED_PASSWORD=' $(ENV_FILE); then \
	  sed -i "s/^TRAEFIK_HASHED_PASSWORD=.*/TRAEFIK_HASHED_PASSWORD=$$HASHED/" $(ENV_FILE); \
	else \
	  echo "TRAEFIK_HASHED_PASSWORD=$$HASHED" >> $(ENV_FILE); \
	fi; \
	echo "✅ Updated TRAEFIK_HASHED_PASSWORD in $(ENV_FILE)"

extract-password:
	@echo "🔐 Extracting JUDGEHOST_PASSWORD from domserver logs for $(ENV) environment..."
	@bash scripts/extract_judgehost_password.sh $(ENV)

# ---- Lifecycle ----

up: check-docker
	@echo "🚀 Starting services for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) $(COMPOSE_FILE) up -d
	@echo "\nℹ️ If you need the judgehost password, run: make extract-password ENV=$(ENV)"

down:
	@echo "🛑 Stopping services for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) $(COMPOSE_FILE) down

restart:
	@echo "🔄 Restarting services for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) $(COMPOSE_FILE) restart

# ---- Debugging ----

logs:
	@echo "📜 Showing logs for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) $(COMPOSE_FILE) logs -f

ps:
	@echo "📋 Listing containers for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) $(COMPOSE_FILE) ps

env:
	@echo "🌍 Using environment: $(ENV)"
	@cat $(ENV_FILE)

# ---- Scaling ----

scale:
	@if [ -z "$(N)" ]; then \
		echo "Usage: make scale ENV=prod N=5"; \
		exit 1; \
	fi
	@echo "⚖️  Scaling judgehost service to $(N) replicas for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) $(COMPOSE_FILE) up -d --scale judgehost=$(N)

# ---- Help ----

help:
	@echo "Available targets:"
	@echo "  check-docker     - Verify Docker is installed & running"
	@echo "  hash-password    - Generate TRAEFIK_HASHED_PASSWORD from plaintext"
	@echo "  extract-password - Extract JUDGEHOST_PASSWORD from domserver logs"
	@echo ""
	@echo "  up       - Start services (default: dev, override with ENV=prod)"
	@echo "  down     - Stop services"
	@echo "  restart  - Restart services"
	@echo "  logs     - Show logs"
	@echo "  ps       - List containers"
	@echo "  env      - Show current environment variables"
	@echo "  scale    - Scale judgehost service (Usage: make scale ENV=prod N=5)"
	@echo ""
	@echo "Example:"
	@echo "  make up ENV=prod"
	@echo "  make scale ENV=prod N=3"
	@echo "  make logs ENV=dev"