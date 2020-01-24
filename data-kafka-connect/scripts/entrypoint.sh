#!/usr/bin/env bash

set -x

CURL="curl --max-time 2 --retry 3 -s"

LOCAL_IPV4=$($CURL http://169.254.169.254/latest/meta-data/local-ipv4)
CONNECT_REST_ADVERTISED_HOST_NAME=${LOCAL_IPV4:-localhost}
DOCKER_ID=$(basename $(cat /proc/1/cpuset))
ECS_HOST_PORT=$($CURL http://172.17.0.1:51678/v1/tasks | jq -r --arg DOCKER_ID "$DOCKER_ID" '.Tasks[] .Containers[] | select(.DockerId == $DOCKER_ID) | .Ports[0].HostPort')
CONNECT_REST_ADVERTISED_PORT=${ECS_HOST_PORT:-28083}

echo --- LOCAL_IPV4 $LOCAL_IPV4
echo --- CONNECT_REST_ADVERTISED_HOST_NAME $CONNECT_REST_ADVERTISED_HOST_NAME
echo --- DOCKER_ID $DOCKER_ID
echo --- ECS_HOST_PORT $ECS_HOST_PORT
echo --- CONNECT_REST_ADVERTISED_PORT $CONNECT_REST_ADVERTISED_PORT

export CONNECT_REST_ADVERTISED_HOST_NAME=$CONNECT_REST_ADVERTISED_HOST_NAME
export CONNECT_REST_ADVERTISED_PORT=$CONNECT_REST_ADVERTISED_PORT

/bootstrap &
/etc/confluent/docker/run
