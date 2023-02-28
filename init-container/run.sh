#!/bin/bash
set -e
set -x
docker  run \
        -d \
        --name init-container \
        --network host \
        --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        init-container:latest tail -f /dev/null
