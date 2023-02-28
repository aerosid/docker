#!/bin/bash
set -e
set -x
echo '/*** server start-up ***/'
sleep 15s
docker exec cb-131 /bin/bash -c /app/init-cb-131-tls-cluster-7.1.1.sh
docker exec cb-132 /bin/bash -c /app/init-cb-132-tls-cluster-7.1.1.sh
docker exec cb-133 /bin/bash -c /app/init-cb-133-tls-cluster-7.1.1.sh
docker exec cb-131 /bin/bash -c /app/post-init-tls-cluster-7.1.1.sh
