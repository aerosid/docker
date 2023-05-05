#!/bin/bash
set -x
set -e
# ${workspaceFolder}\\.copy-on-save.sh ${file} ${relativeFile}
source .config.sh
scp -F ./ssh-config -i ./id_rsa $1 $user@$host:$target/$2
# ${workspaceFolder}: /home/ubuntu/vscode/docker
# ${file}: /home/ubuntu/vscode/docker/portainer/run.sh