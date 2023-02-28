#!/bin/bash
scp -F ./ssh-config -i ./id_rsa -r ./docker $1:~