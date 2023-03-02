#!/bin/bash
set -e
set -x
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -sha256 -key ca.key -out ca.pem -subj "/CN=Couchbase Root CA/OU=IT/O=Wibmo/L=Bangalore/ST=Karnataka/C=IN"
openssl x509 -subject -issuer -startdate -enddate -noout -in ca.pem
openssl rsa -check -noout -in ca.key
openssl rsa -modulus -noout -in ca.key | openssl md5
openssl x509 -modulus -noout -in ca.pem | openssl md5 # value must match with previous command
