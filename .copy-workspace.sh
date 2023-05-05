#!/bin/bash
set -x
set -e
source .config.sh
# copies VSCode workspace ($source) files and folders under $(target)
scp -F ./ssh-config -i ./id_rsa -r $source $user@$host:$target