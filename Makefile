include makester/makefiles/base.mk
include makester/makefiles/python-venv.mk

COMPOSE_FILES = -f $(SERVICE_NAME)/docker-compose.yml
DEV_COMPOSE_FILES = -f $(SERVICE_NAME)/docker-compose-dev.yml -f $(SERVICE_NAME)/docker-compose-minio.yml

init: pip-requirements

local-build-config:
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(DEV_COMPOSE_FILES) \
      config

prebuild:
	$(PYTHON) ./prebuild --environment local
	
local-build-up: local-build-down prebuild
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(DEV_COMPOSE_FILES) \
      up -d
	@$(PYTHON) $(SERVICE_NAME)/scripts/backoff -p 8081 -p 8082 -p 28083
	@$(PYTHON) $(SERVICE_NAME)/scripts/bootstrap

local-build-down:
	@SERVICE_NAME=$(SERVICE_NAME) \
      HASH=$(HASH) \
      $(DOCKER_COMPOSE) --project-directory $(SERVICE_NAME) \
      $(COMPOSE_FILES) $(DEV_COMPOSE_FILES) \
      down

help: base-help python-venv-help
	@echo "(Makefile)\n\
  init                 Build the local virtual environment\n\
  local-build-up:      Create a local Kafka Connect pipeline that streams data to an S3-like store (MINIO)\n\
  local-build-down:    Destroy local Kafka Connect pipeline\n\
  local-build-config:  Local Kafka Connect pipeline docker-compose config\n\
  local-rmi:           Remove local Kafka Connect docker image\n\
	";


.PHONY: help
