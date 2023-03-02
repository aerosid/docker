#!/bin/bash
# Create private key
openssl genrsa -out ./host.key 2048
# Create Certificate Signing Request (CSR)
openssl req \
        -new \
        -key ./host.key \
        -out ./host.csr \
        -subj "/CN=127.0.0.1/OU=Engineering/O=Wibmo/L=Bangalore/ST=Karnataka/C=IN"
# Create self-signed certificate
openssl x509 \
        -signkey ./host.key \
        -days 365 \
        -req \
        -in ./host.csr \
        -out ./host.pem
# Validate PEM format?
openssl x509 \
        -text \
        -in ./host.pem
# Display cert. info
openssl x509 -subject -issuer -startdate -enddate -noout -in ./host.pem
# Check private key
openssl rsa -check -noout -in ./host.key
# Check that key and cert. match
openssl rsa -modulus -noout -in ./host.key | openssl md5
openssl x509 -modulus -noout -in ./host.pem | openssl md5 #same value as previous command output
