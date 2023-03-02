#!/bin/bash
docker  run \
        -d \
        -e MYSQL_ROOT_PASSWORD=root \
        -e MYSQL_DATABASE=sample \
        -e MYSQL_USER=ubuntu \
        -e MYSQL_PASSWORD=hello \
        --name mysql \
        --network host \
        --rm \
        -v /home/ubuntu/frm-cloud/docker/mysql/config/trident.sql:/tmp/trident.sql:ro \
        -v /home/ubuntu/frm-cloud/docker/mysql/config/db.sh:/tmp/db.sh \
        mysql:8.0.30