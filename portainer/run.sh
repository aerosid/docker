#!/bin/bash
# Login: admin A8(k*2S*muxM
docker run \
  --detach \
  --name portainer \
  --publish 9000:9000 \
  --rm \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume portainer-data:/data \
  portainer:latest
  
