# Directory for persistent data
WP_DATA = /home/ryan99/data/wordpress
DB_DATA = /home/ryan99/data/mariadb

# Build rules
all: up

up: build
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
	@docker stop $$(docker ps -qa) 2>/dev/null || true
	@docker rm $$(docker ps -qa) 2>/dev/null || true
	@docker rmi -f $$(docker images -qa) 2>/dev/null || true
	@docker volume rm $$(docker volume ls -q) 2>/dev/null || true
	@docker network rm $$(docker network ls -q) 2>/dev/null || true
	@rm -rf $(WP_DATA) $(DB_DATA) 2>/dev/null || true

re: clean up

prune: clean
	@docker system prune -a --volumes -f

.PHONY: all up down stop start build ng mdb wp clean re prune
