SERVICE_NAME=data-kafka-connect
CONFIG=dev

# Set globals.
GIT=$(shell which git 2>/dev/null)
DOCKER_COMPOSE=$(shell which docker-compose 2>/dev/null)
DOCKER=$(shell which docker 2>/dev/null)

COMPOSE_FILES = -f $(SERVICE_NAME)/docker-compose.yml
DEV_COMPOSE_FILES = -f $(SERVICE_NAME)/docker-compose-dev.yml -f $(SERVICE_NAME)/docker-compose-minio.yml

local-build-config:
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(DEV_COMPOSE_FILES) \
      CONFIG

local-build-up: local-build-down pre-build
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(DEV_COMPOSE_FILES) \
      up -d

local-build-down:
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(DEV_COMPOSE_FILES) \
      down
	@$(DOCKER) rmi data-kafka-connect:${HASH} || true

publish: build

clean:
	$(GIT) clean -xdf -e .vagrant -e *.swp -e 2env -e 3env

print-%:
	@echo '$*=$($*)'

help:
	@echo "\n \
	Targets\n\
	------------------------------------------------------------------------\n \
	dev-build-up:       Create a local Kafka Connect pipeline that streams data to an S3-like store (MINIO).\n \
	dev-build-down:     Destroy local Kafka Connect pipeline.\n \
	dev-build-config:   Local Kafka Connect pipeline docker-compose config.\n \
	print-<var>:        Display the Makefile global variable '<var>' value.\n \
	clean:              Remove all files not tracked by Git.\n \
	";

.PHONY: help config
