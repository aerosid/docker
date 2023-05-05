#!/bin/bash
# Login: admin A8(k*2S*muxM
docker run \
  --detach \
  --name portainer \
  --publish 9000:9000 \
  --rm \
  --volume /run/user/1000/docker.sock:/var/run/docker.sock \
  --volume /home/ubuntu/vscode/docker/portainer/data:/data \
  portainer:latest
  