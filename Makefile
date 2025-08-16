include ./srcs/.env
export

# Colors
RED		=	\033[1;31m
GREEN	=	\033[1;32m
YELLOW	=	\033[1;33m
BLUE	=	\033[1;34m
RESET	=	\033[0m

# Detect environment
LOGIN_NAME := $(shell whoami)
UNAME_S := $(shell uname -s)

WP_DATA=$(DATA_PATH)/wordpress
DB_DATA=$(DATA_PATH)/mariadb

# Build rules
all: up

up: build
	@echo "$(BLUE)Creating data directories at:$(RESET) $(DATA_PATH)"
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)
	docker-compose -f ./srcs/docker-compose.yml up -d

down:
	docker-compose -f ./srcs/docker-compose.yml down

stop:
	docker-compose -f ./srcs/docker-compose.yml stop

start:
	docker-compose -f ./srcs/docker-compose.yml start

build:
	@clear
	@echo "$(YELLOW)Building containers for user:$(RESET) $(LOGIN_NAME) on $(UNAME_S)"
	docker-compose -f ./srcs/docker-compose.yml build

# Debug shells
ng:
	@docker exec -it nginx bash

mdb:
	@docker exec -it mariadb bash

wp:
	@docker exec -it wordpress bash

# Cleanup rules
clean:
	@echo "$(RED)Stopping all containers.$(RESET)"
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker rm $$(docker ps -qa) 2>/dev/null || true
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@echo "$(YELLOW)Note: Data not removed. Preserved in:$(RESET) $(DATA_PATH)"

fclean: clean
	@echo "$(RED)WARNING: This will delete ALL data!$(RESET)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ]
	@rm -rf $(DATA_PATH) 2>/dev/null || true
	@echo "$(GREEN)All data removed.$(RESET)"

re: clean up

prune: fclean
	@echo "$(RED)Pruning unused Docker resources.$(RESET)"
	@docker system prune -a --volumes -f

# Show data paths
info:
	@echo "User: $(LOGIN_NAME)"
	@echo "OS: $(UNAME_S)"
	@echo "Base directory: $(DATA_PATH)"
	@echo "WordPress data: $(WP_DATA)"
	@echo "MariaDB data: $(DB_DATA)"

logs:
	docker logs mariadb
	docker logs wordpress
	docker logs nginx

.PHONY: all up down stop start build ng mdb wp clean fclean re prune info