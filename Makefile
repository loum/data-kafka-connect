.SILENT:
.DEFAULT_GOAL := help

include makester/makefiles/makester.mk
include makester/makefiles/python-venv.mk
include makester/makefiles/docker.mk

DEV_COMPOSE_FILES = -f docker/docker-compose-dev.yml -f docker/docker-compose-minio.yml
MAKESTER__COMPOSE_FILES = -f docker/docker-compose.yml $(DEV_COMPOSE_FILES)
MAKESTER__COMPOSE_RUN_CMD = SERVICE_NAME=$(MAKESTER__SERVICE_NAME) HASH=$(HASH)\
 $(DOCKER_COMPOSE)\
 --project-name $(MAKESTER__PROJECT_NAME)\
 $(MAKESTER__COMPOSE_FILES) $(COMPOSE_CMD)

include makester/makefiles/compose.mk
init: pip-requirements

stack-config: compose-config

prebuild:
	$(PYTHON) ./docker/scripts/prebuild --environment local

backoff:
	@$(PYTHON) makester/scripts/backoff -d "Kafka Schema Registry" -p 8081 localhost
	@$(PYTHON) makester/scripts/backoff -d "Kafka ReST" -p 8082 localhost
	@$(PYTHON) makester/scripts/backoff -d "Kafka Connect" -p 28083 localhost

kafka-register-schema:
	$(info ### Kafka Schema Registry: Register the sample Avro schema ...)
	$(shell which curl) -X POST\
 -H "Content-Type: application/vnd.schemaregistry.v1+json"\
 --data @docker/files/schemas/develop/sample-sink-avro-schema.json\
 http://localhost:8081/subjects/sample-sink-value/versions

kafka-message-producer:
	$(info ### Confluent REST API: Create a message producer ...)
	$(shell which curl) -X POST\
 -H "Content-Type: application/vnd.kafka.avro.v2+json"\
 -H "Accept: application/vnd.kafka.v2+json"\
 --data '{"value_schema_id": 1, "records": [{"value": {"data": {"Id": "98cf1dc6-6f2b-4d9d-b733-f45e7d71aded"}}}]}'\
 http://localhost:8082/topics/sample-sink

kafka-sink-to-s3:
	$(info ### Kafka Connect: Sink to s3 ...)
	$(shell which curl) --silent -X POST\
 -H "Content-Type: application/json"\
 --data @docker/files/connectors/properties/sample-sink-connector.s3.properties.json\
 http://localhost:28083/connectors | jq .
	
bootstrap: kafka-register-schema kafka-message-producer kafka-sink-to-s3

stack-up: prebuild compose-up backoff

stack-down: compose-down

help: makester-help compose-help python-venv-help
	@echo "(Makefile)\n\
  init                 Build the local virtual environment\n\
  stack-up:            Create a local Kafka Connect pipeline that streams data to an S3-like store (MINIO)\n\
  stack-down:          Destroy local Kafka Connect pipeline\n\
  stack-config:        Local Kafka Connect pipeline docker-compose config\n\
  bootstrap:           Run all tutorial steps\n\
  rm-image:            Remove local Kafka Connect docker image\n"

.PHONY: help prebuild
