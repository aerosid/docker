#!/bin/bash
set -e
set -x
cat > ./node.ext <<EOF
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
extendedKeyUsage=serverAuth
keyUsage=digitalSignature,keyEncipherment
subjectAltName=IP:127.0.0.1
EOF
openssl genrsa -out ./pkey.key 2048
openssl req -new -key ./pkey.key -out ./node.csr -subj "/CN=Couchbase Server/OU=Engineering/O=Wibmo/L=Bangalore/ST=Karnataka/C=IN"
openssl x509 -CA ./ca.pem -CAkey ./ca.key -CAcreateserial -days 365 -req \
-in ./node.csr \
-out ./chain.pem \
-extfile ./node.ext
openssl x509 -subject -issuer -startdate -enddate -noout -in ./chain.pem
openssl rsa -check -noout -in ./pkey.key
openssl rsa -modulus -noout -in ./pkey.key | openssl md5
openssl x509 -modulus -noout -in ./chain.pem | openssl md5