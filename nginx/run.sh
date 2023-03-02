#!/bin/bash
docker  run \
        -d \
        --name nginx \
        --network host \
        --rm \
        -v ~/docker/nginx/www:/usr/share/nginx/html:ro \
        -v ~/docker/nginx/config/default.conf:/etc/nginx/nginx.conf:ro \
        nginx:latest