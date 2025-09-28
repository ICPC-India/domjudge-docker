# Makefile for DOMjudge Docker Deployment

# Default environment (can be overridden: make up ENV=prod)
ENV ?= dev

# Compose file location (adjust if needed)
COMPOSE_FILE := config/docker-compose.$(ENV).ymldeplo location
ENV_FILE := .env.$(ENV)

# Docker Compose command (use 'docker compose' if using newer Docker)
DC := docker-compose

# Helper to check if env file exists
ifeq (,$(wildcard $(ENV_FILE)))
  $(error Environment file '$(ENV_FILE)' not found!)
endif

.PHONY: up down restart logs ps env help extract-password hash-password
hash-password:
	@echo "Generating TRAEFIK_HASHED_PASSWORD from traefik_PLAINTEXT_PASSWORD in $(ENV_FILE)..."
	PLAINTEXT=$$(grep '^TRAEFIK_PLAINTEXT_PASSWORD=' $(ENV_FILE) | cut -d'=' -f2-); \
	if [ -z "$$PLAINTEXT" ]; then \
	  echo "traefik_PLAINTEXT_PASSWORD not set in $(ENV_FILE)"; exit 1; \
	fi; \
	HASHED=$$(openssl passwd -apr1 "$$PLAINTEXT"); \
	if grep -q '^TRAEFIK_HASHED_PASSWORD=' $(ENV_FILE); then \
	  sed -i "s/^TRAEFIK_HASHED_PASSWORD=.*/TRAEFIK_HASHED_PASSWORD=$$HASHED/" $(ENV_FILE); \
	else \
	  echo "TRAEFIK_HASHED_PASSWORD=$$HASHED" >> $(ENV_FILE); \
	fi; \
	echo "Updated TRAEFIK_HASHED_PASSWORD in $(ENV_FILE)"

up:
	@echo "Starting services for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) up -d
	@echo "\nIf you need the judgehost password, run: make extract-password ENV=$(ENV)"
extract-password:
	@echo "Extracting JUDGEHOST_PASSWORD from domserver logs for $(ENV) environment..."
	bash $(dir $(lastword $(MAKEFILE_LIST)))extract_judgehost_password.sh $(ENV)

down:
	@echo "Stopping services for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) down

restart:
	@echo "Restarting services for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) restart

logs:
	@echo "Showing logs for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) logs -f

ps:
	@echo "Listing containers for $(ENV) environment..."
	$(DC) --env-file $(ENV_FILE) -f $(COMPOSE_FILE) ps

env:
	@echo "Using environment: $(ENV)"
	@cat $(ENV_FILE)

help:
	@echo "Available targets:"
	@echo "  up       - Start services (default: dev, override with ENV=prod)"
	@echo "  down     - Stop services"
	@echo "  restart  - Restart services"
	@echo "  logs     - Show logs"
	@echo "  ps       - List containers"
	@echo "  env      - Show current environment variables"
	@echo "  help     - Show this help message"
	@echo "  hash-password - Generate TRAEFIK_HASHED_PASSWORD from traefik_PLAINTEXT_PASSWORD in .env file"
