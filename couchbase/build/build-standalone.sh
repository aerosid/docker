#!/bin/bash
set -e
set -x
docker image rm -f $(docker images -f dangling=true -q) # remove dangling images
docker --build ./standalone-dockerfile --tag couchbase:latest