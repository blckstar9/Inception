NAME = inception

COMPOSE = sudo docker compose \
	--env-file srcs/.env \
	-f srcs/docker-compose.yml

DATA_DIR = /home/aybelaou/data

.DEFAULT_GOAL := all

.PHONY: all up down build re ps logs stop start

all: up

up:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

build:
	$(COMPOSE) build

re: down up

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs --tail=100

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start
