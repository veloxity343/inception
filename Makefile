include ./srcs/.env
export

# Colors
RED     = \033[1;31m
GREEN   = \033[1;32m
YELLOW  = \033[1;33m
BLUE    = \033[1;34m
RESET   = \033[0m

# Scoped compose
COMPOSE = docker compose -p inception -f ./srcs/docker-compose.yml

# Detect environment
LOGIN_NAME := $(shell whoami)
UNAME_S    := $(shell uname -s)

WP_DATA = $(DATA_PATH)/wordpress
DB_DATA = $(DATA_PATH)/mariadb

# Default rule
all: up

# Build and start containers
up: build
	@echo "$(BLUE)Creating data directories at:$(RESET) $(DATA_PATH)"
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

build:
	@clear
	@echo "$(YELLOW)Building containers for user:$(RESET) $(LOGIN_NAME) on $(UNAME_S)"
	$(COMPOSE) build

# Debug shells
ng:
	@docker exec -it inception-nginx bash

mdb:
	@docker exec -it inception-mariadb bash

wp:
	@docker exec -it inception-wordpress bash

# Cleanup rules
clean:
	@echo "$(RED)Stopping and removing Inception containers/networks.$(RESET)"
	$(COMPOSE) down --remove-orphans
	@echo "$(YELLOW)Note: Persistent data (volumes) is still preserved.$(RESET)"

fclean:
	@echo "$(RED)WARNING: This will delete ALL Inception data (volumes)!$(RESET)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] && \
	$(COMPOSE) down -v
	@echo "$(GREEN)All project volumes removed safely.$(RESET)"

re: clean up

# Show data paths
info:
	@echo "User: $(LOGIN_NAME)"
	@echo "OS: $(UNAME_S)"
	@echo "Base directory: $(DATA_PATH)"
	@echo "WordPress data: $(WP_DATA)"
	@echo "MariaDB data: $(DB_DATA)"

logs:
	@docker logs inception-mariadb
	@docker logs inception-wordpress
	@docker logs inception-nginx

.PHONY: all up down stop start build ng mdb wp clean fclean re info logs
