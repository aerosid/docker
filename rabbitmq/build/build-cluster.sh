#!/bin/bash
set -e
set -x
docker build -t rabbitmq:cluster -f cluster-dockerfile .

