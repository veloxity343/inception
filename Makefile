include ./srcs/.env
export

# Colors
RED     = \033[1;31m
GREEN   = \033[1;32m
YELLOW  = \033[1;33m
BLUE    = \033[1;34m
CYAN    = \033[1;36m
PURPLE  = \033[1;35m
RESET   = \033[0m

# Project settings
PROJECT = inception
COMPOSE = docker compose -p $(PROJECT) -f ./srcs/docker-compose.yml
COMPOSE_BONUS = docker compose -p $(PROJECT) -f ./srcs/docker-compose.yml -f ./srcs/docker-compose.bonus.yml

# Environment
LOGIN_NAME := $(shell whoami)
UNAME_S    := $(shell uname -s)
TIMESTAMP  := $(shell date +%Y%m%d_%H%M%S)

# Data paths
WP_DATA = $(DATA_PATH)/wordpress
DB_DATA = $(DATA_PATH)/mariadb
RD_DATA = $(DATA_PATH)/redis
AD_DATA = $(DATA_PATH)/adminer
PT_DATA = $(DATA_PATH)/portainer

# Log directory
LOG_DIR = ./logs
LOG_FILE = $(LOG_DIR)/inception_$(TIMESTAMP).logs

# Services
CORE_SERVICES = mariadb wordpress nginx
BONUS_SERVICES = redis adminer ftp portainer portfolio
ALL_SERVICES = $(CORE_SERVICES) $(BONUS_SERVICES)

# Service-specific compose
define get_compose_cmd
$(if $(filter $1,$(BONUS_SERVICES)),$(COMPOSE_BONUS),$(COMPOSE))
endef

#=============================================================================
# BUILD AND START
#=============================================================================

# Default target
all: setup up

# Full setup with logging
setup: create-dirs create-logs
	@echo "$(BLUE)Setting up inception for:$(RESET)"
	@echo "$(YELLOW)User: $(LOGIN_NAME) | OS: $(UNAME_S) | Time: $(TIMESTAMP)$(RESET)"

# Build services
build: setup
	@echo "$(YELLOW)Building core services.$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE) build 2>&1 | tee -a $(LOG_FILE)

build-bonus: setup
	@echo "$(YELLOW)Building bonus services.$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE_BONUS) build $(BONUS_SERVICES) 2>&1 | tee -a $(LOG_FILE)

build-all: setup
	@echo "$(YELLOW)Building all services.$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE_BONUS) build 2>&1 | tee -a $(LOG_FILE)

build-%: setup
	@echo "$(YELLOW)Building $* container.$(RESET)" | tee -a $(LOG_FILE)
	$(call get_compose_cmd,$*) build $* 2>&1 | tee -a $(LOG_FILE)

# Start services
up: build
	@echo "$(GREEN)Starting core services.$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE) up -d 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) --no-print-directory status

up-bonus: build-bonus
	@echo "$(GREEN)Starting bonus services.$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE_BONUS) up -d $(BONUS_SERVICES) 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) --no-print-directory status

up-all: build-all
	@echo "$(GREEN)Starting all services.$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE_BONUS) up -d 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) --no-print-directory status

up-%: build-%
	@echo "$(GREEN)Starting $* service.$(RESET)" | tee -a $(LOG_FILE)
	$(call get_compose_cmd,$*) up -d $* 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) --no-print-directory status-$*

#=============================================================================
# LIFECYCLE COMMANDS
#=============================================================================

# Global service management
down:
	@echo "$(RED)Stopping all services.$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE) down 2>&1 | tee -a $(LOG_FILE)

# Stop services
down-%:
	@echo "$(RED)Stopping $* service.$(RESET)" | tee -a $(LOG_FILE)
	$(call get_compose_cmd,$*) stop $* 2>&1 | tee -a $(LOG_FILE)

restart: down up

restart-%: down-% up-%
	@echo "$(CYAN)Restarted $* service$(RESET)"

start:
	@echo "$(GREEN)Starting existing containers.$(RESET)"
	$(COMPOSE) start

start-%:
	@echo "$(GREEN)Starting $* container.$(RESET)"
	$(call get_compose_cmd,$*) start $*

stop:
	@echo "$(YELLOW)Stopping containers.$(RESET)"
	$(COMPOSE) stop

stop-%:
	@echo "$(YELLOW)Stopping $* container.$(RESET)"
	$(call get_compose_cmd,$*) stop $*

#=============================================================================
# REBUILD TARGETS
#=============================================================================

# Rebuild specific service
rebuild-%: setup
	@echo "$(PURPLE)Force rebuilding $* from scratch.$(RESET)" | tee -a $(LOG_FILE)
	$(call get_compose_cmd,$*) build --no-cache $* 2>&1 | tee -a $(LOG_FILE)
	$(call get_compose_cmd,$*) up -d $* 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) --no-print-directory status-$*

# Rebuild and restart specific service
redeploy-%:
	@echo "$(PURPLE)Redeploying $* service.$(RESET)" | tee -a $(LOG_FILE)
	$(call get_compose_cmd,$*) stop $* 2>&1 | tee -a $(LOG_FILE)
	$(call get_compose_cmd,$*) build --no-cache $* 2>&1 | tee -a $(LOG_FILE)
	$(call get_compose_cmd,$*) up -d $* 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) --no-print-directory status-$*

#=============================================================================
# STATUS AND MONITORING
#=============================================================================

# Show status of all services
status:
	@echo "$(CYAN)=== Container Status ===$(RESET)"
	@$(COMPOSE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "$(CYAN)=== Health Status ===$(RESET)"
	@for service in $(ALL_SERVICES); do \
		health=$$(docker inspect --format='{{.State.Health.Status}}' $(PROJECT)-$$service 2>/dev/null || echo "no-health-check"); \
		if [ "$$health" = "healthy" ]; then \
			echo "$(GREEN)✓ $$service: $$health$(RESET)"; \
		elif [ "$$health" = "unhealthy" ]; then \
			echo "$(RED)✗ $$service: $$health$(RESET)"; \
		else \
			echo "$(YELLOW)- $$service: $$health$(RESET)"; \
		fi; \
	done

# Status of specific service
status-%:
	@echo "$(CYAN)=== $* Status ===$(RESET)"
	@$(call get_compose_cmd,$*) ps $*
	@health=$$(docker inspect --format='{{.State.Health.Status}}' $(PROJECT)-$* 2>/dev/null || echo "no-health-check"); \
	echo "Health: $$health"

# Watch logs in real-time
watch:
	@echo "$(CYAN)Watching all service logs.$(RESET)"
	$(COMPOSE) logs -f

watch-%:
	@echo "$(CYAN)Watching $* logs.$(RESET)"
	$(call get_compose_cmd,$*) logs -f $*

#=============================================================================
# LOGGING TARGETS
#=============================================================================

# View recent logs
logs:
	@echo "$(CYAN)=== Recent Logs ===$(RESET)"
	$(COMPOSE) logs --tail=50

logs-%:
	@echo "$(CYAN)=== Recent $* Logs ===$(RESET)"
	$(call get_compose_cmd,$*) logs --tail=50 $*

# Save logs to file
save-logs:
	@echo "$(BLUE)Saving logs to $(LOG_DIR)/containers_$(TIMESTAMP).logs$(RESET)"
	@$(COMPOSE) logs > $(LOG_DIR)/containers_$(TIMESTAMP).logs
	@echo "$(GREEN)Logs saved successfully$(RESET)"

# Archive logs with timestamp
archive-logs:
	@echo "$(BLUE)Archiving logs...$(RESET)"
	@mkdir -p $(LOG_DIR)/archive
	@for service in $(ALL_SERVICES); do \
		$(call get_compose_cmd,$$service) logs $$service > $(LOG_DIR)/archive/$${service}_$(TIMESTAMP).logs 2>/dev/null || true; \
	done
	@echo "$(GREEN)Logs archived to $(LOG_DIR)/archive/$(RESET)"

#=============================================================================
# DEBUGGING AND SHELL ACCESS
#=============================================================================

# Interactive shells
shell-%:
	@echo "$(CYAN)Opening shell in $* container.$(RESET)"
	@docker exec -it $(PROJECT)-$* bash || docker exec -it $(PROJECT)-$* sh

# Quick shell aliases
mdb:
	@$(MAKE) --no-print-directory shell-mariadb

ng:
	@$(MAKE) --no-print-directory shell-nginx

wp:
	@$(MAKE) --no-print-directory shell-wordpress

rd:
	@$(MAKE) --no-print-directory shell-redis

ad:
	@$(MAKE) --no-print-directory shell-adminer

ftp:
	@$(MAKE) --no-print-directory shell-ftp

pt:
	@$(MAKE) --no-print-directory shell-portainer

fo:
	@$(MAKE) --no-print-directory shell-portfolio

# Execute commands in containers
exec-%:
	@echo "$(CYAN)Executing command in $* container.$(RESET)"
	@echo "Usage: make exec-SERVICE cmd='your command'"
	@docker exec -it $(PROJECT)-$* $(cmd)

#=============================================================================
# CLEANUP TARGETS
#=============================================================================

# Clean containers and networks
clean:
	@echo "$(RED)Stopping and removing containers/networks.$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE) down --remove-orphans 2>&1 | tee -a $(LOG_FILE)
	@echo "$(YELLOW)Volumes preserved. Use 'make fclean' to remove data.$(RESET)"

# Clean specific service
clean-%:
	@echo "$(RED)Cleaning $* service ($(PROJECT) only).$(RESET)"
	$(call get_compose_cmd,$*) rm -sf $*
	@docker rmi $*:rcheong 2>/dev/null || echo "No $* image to remove"

# Full clean including volumes
fclean:
	@echo "$(RED)WARNING: This will delete $(PROJECT) data only!$(RESET)"
	@echo "$(RED)Project data locations:$(RESET)"
	@echo "  - WordPress: $(WP_DATA)"
	@echo "  - MariaDB: $(DB_DATA)"  
	@echo "  - Redis: $(RD_DATA)"
	@echo "  - Adminer: $(AD_DATA)"
	@echo "  - Portainer: $(PT_DATA)"
	@echo ""
	@read -p "Type 'DELETE' to confirm: " confirm && [ "$confirm" = "DELETE" ] || (echo "Aborted." && exit 1)
	@echo "$(RED)Removing $(PROJECT) containers, networks, and volumes...$(RESET)" | tee -a $(LOG_FILE)
	$(COMPOSE) down -v --remove-orphans 2>&1 | tee -a $(LOG_FILE)
	@$(MAKE) --no-print-directory clean-images
	@echo "$(GREEN)$(PROJECT) cleanup finished. Other Docker projects unaffected.$(RESET)"

# Remove only project-specific images
clean-images:
	@echo "$(YELLOW)Removing $(PROJECT) images only.$(RESET)"
	@for service in $(ALL_SERVICES); do \
		docker rmi $service:rcheong 2>/dev/null || true; \
		docker rmi $(PROJECT)-$service 2>/dev/null || true; \
	done
	@echo "$(GREEN)Project images cleaned$(RESET)"

#=============================================================================
# UTILITY TARGETS
#=============================================================================

# Create necessary directories
create-dirs:
	@echo "$(BLUE)Creating data directories.$(RESET)"
	@mkdir -p $(WP_DATA) $(DB_DATA) $(RD_DATA) $(AD_DATA) $(PT_DATA)

# Create log directory
create-logs:
	@mkdir -p $(LOG_DIR)

# Show environment info
info:
	@echo "$(CYAN)=== Environment Info ===$(RESET)"
	@echo "User: $(LOGIN_NAME)"
	@echo "OS: $(UNAME_S)"
	@echo "Project: $(PROJECT)"
	@echo "Timestamp: $(TIMESTAMP)"
	@echo ""
	@echo "$(CYAN)=== Data Paths ===$(RESET)"
	@echo "Base: $(DATA_PATH)"
	@echo "WordPress: $(WP_DATA)"
	@echo "MariaDB: $(DB_DATA)"
	@echo "Redis: $(RD_DATA)"
	@echo "Adminer: $(AD_DATA)"
	@echo "Portainer: $(PT_DATA)"
	@echo ""
	@echo "$(CYAN)=== Log Files ===$(RESET)"
	@echo "Current: $(LOG_FILE)"
	@echo "Directory: $(LOG_DIR)"

# Show available services
services:
	@echo "$(CYAN)=== Available Services ===$(RESET)"
	@echo "Core services: $(CORE_SERVICES)"
	@echo "Bonus services: $(BONUS_SERVICES)"

# Show help
help:
	@echo "$(CYAN)=== Inception Makefile Help ===$(RESET)"
	@echo ""
	@echo "$(YELLOW)Main Commands:$(RESET)"
	@echo "  make all              # Full setup and start"
	@echo "  make up               # Build and start all services"
	@echo "  make down             # Stop all services"  
	@echo "  make restart          # Restart all services"
	@echo ""
	@echo "$(YELLOW)Service-Specific Commands:$(RESET)"
	@echo "  make build-SERVICE    # Build specific service"
	@echo "  make up-SERVICE       # Start specific service"
	@echo "  make down-SERVICE     # Stop specific service"
	@echo "  make restart-SERVICE  # Restart specific service"
	@echo "  make rebuild-SERVICE  # Rebuild from scratch"
	@echo "  make redeploy-SERVICE # Stop, rebuild, start"
	@echo ""
	@echo "$(YELLOW)Monitoring:$(RESET)"
	@echo "  make status           # Show all service status"
	@echo "  make logs             # Show recent logs"
	@echo "  make watch            # Follow logs in real-time"
	@echo "  make save-logs        # Save logs to file"
	@echo ""
	@echo "$(YELLOW)Debug:$(RESET)"
	@echo "  make shell-SERVICE    # Open shell in container"
	@echo ""
	@echo "$(YELLOW)Cleanup:$(RESET)"
	@echo "  make clean            # Remove containers (keep data)"
	@echo "  make fclean           # Remove everything including data"
	@echo "  make clean-images     # Remove project images only"
	@echo ""
	@echo "$(YELLOW)Available Services:$(RESET) mariadb, nginx, wordpress, redis, adminer, ftp"
	@echo "$(YELLOW)Note:$(RESET) All SERVICE commands auto-detect core vs bonus services"

# Complete project rebuild  
re: clean up-all

#=============================================================================
# PHONY DECLARATIONS
#=============================================================================

.PHONY: all setup build build-bonus build-all up up-bonus up-all down restart start stop \
        status watch logs save-logs archive-logs clean fclean clean-images create-dirs \
        create-logs info services help re ng mdb wp rd ad ftp pt fo

#=============================================================================
# QUICK REFERENCE
#=============================================================================

# Uncomment for quick reference at top of file
# 
# QUICK COMMANDS:
# make up-wordpress      # Build and start only WordPress 
# make rebuild-mariadb   # Rebuild MariaDB from scratch
# make logs-nginx        # View Nginx logs
# make shell-redis       # Open Redis shell
# make status            # Show all service status  
# make help              # Full help menu
