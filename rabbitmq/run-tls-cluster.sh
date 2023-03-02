#!/bin/bash
set -e
set -x
# docker network create --subnet=10.229.213.0/24 --gateway=10.229.213.1 hdfc-213
docker run \
  -d \
  --network hdfc-213 \
  --hostname rabbit-217 \
  --ip 10.229.213.217 \
  --name rabbit-217 \
  -p 15672:15672 \
  --rm \
  -v ~/frm-cloud/docker/rabbitmq/config/rabbitmq-cluster.conf:/etc/rabbitmq/rabbitmq.conf:ro \
  -v ~/frm-cloud/docker/rabbitmq/config/host.pem:/etc/rabbitmq/rabbitmq.crt:ro \
  -v ~/frm-cloud/docker/rabbitmq/config/host.key:/etc/rabbitmq/rabbitmq.key:ro \
  rabbitmq:cluster

docker run \
  -d \
  --network hdfc-213 \
  --hostname rabbit-218 \
  --ip 10.229.213.218 \
  --name rabbit-218 \
  --rm \
  -v ~/frm-cloud/docker/rabbitmq/config/rabbitmq-cluster.conf:/etc/rabbitmq/rabbitmq.conf:ro \
  -v ~/frm-cloud/docker/rabbitmq/config/host.pem:/etc/rabbitmq/rabbitmq.crt:ro \
  -v ~/frm-cloud/docker/rabbitmq/config/host.key:/etc/rabbitmq/rabbitmq.key:ro \
  rabbitmq:cluster