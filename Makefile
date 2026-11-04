NAME = inception


COMPOSE = sudo docker compose \
	--env-file srcs/.env \
	-f srcs/docker-compose.yml

.DEFAULT_GOAL := all

.PHONY: all setup up down build re ps logs stop start

all: up

setup:
	sh srcs/tools/setup.sh

up: setup
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

build: setup
	$(COMPOSE) build

re: setup down up

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs --tail=100

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start
