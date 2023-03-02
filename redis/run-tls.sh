#!/bin/bash
docker  run \
        -it \
        --name redis \
        --rm \
        -v ~/docker/redis/config/redis-tls.conf:/etc/redis/redis.conf:ro \
        -v ~/docker/redis/config/redis.pem:/etc/ssl/certs/redis.crt:ro \
        -v ~/docker/redis/config/redis.key:/etc/ssl/certs/redis.key:ro \
        ubuntu/redis:6.0-22.04_beta