#!/bin/bash
docker  run \
        -d \
        --name rabbitmq \
        --rm \
        -v ~/docker/rabbitmq/config/rabbitmq-tls.conf:/etc/rabbitmq/rabbitmq.conf:ro \
        -v ~/docker/rabbitmq/config/host.pem:/etc/rabbitmq/rabbitmq.crt:ro \
        -v ~/docker/rabbitmq/config/host.key:/etc/rabbitmq/rabbitmq.key:ro \
        rabbitmq:3.9.2