#!/bin/bash
set -e
set -x
echo '/*** node cert. ***/'
cd /tmp
cat > /tmp/node.ext <<EOF
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
extendedKeyUsage=serverAuth
keyUsage=digitalSignature,keyEncipherment
subjectAltName=IP:10.229.214.132
EOF
openssl genrsa -out /tmp/pkey.key 2048
openssl req -new -key /tmp/pkey.key -out /tmp/node.csr \
-subj "/CN=Couchbase Node 132/OU=Engineering/O=Wibmo/L=Bangalore/ST=Karnataka/C=IN"
openssl x509 -CA /app/config/ca.pem -CAkey /app/config/ca.key -CAcreateserial -days 365 -req \
-in /tmp/node.csr \
-out /tmp/chain.pem \
-extfile /tmp/node.ext
openssl x509 -subject -issuer -startdate -enddate -noout -in ./chain.pem
openssl rsa -check -noout -in ./pkey.key
openssl rsa -modulus -noout -in ./pkey.key | openssl md5
openssl x509 -modulus -noout -in ./chain.pem | openssl md5
echo '/*** update certs. ***/'
# update node cert.
mkdir -p /opt/couchbase/var/lib/couchbase/inbox
cp /tmp/chain.pem /opt/couchbase/var/lib/couchbase/inbox/chain.pem
cp /tmp/pkey.key /opt/couchbase/var/lib/couchbase/inbox/pkey.key
chown -R couchbase:couchbase /opt/couchbase/var/lib/couchbase/inbox
chmod +x /opt/couchbase/var/lib/couchbase/inbox
chmod 0600 /opt/couchbase/var/lib/couchbase/inbox/*
find /opt/couchbase/var/lib/couchbase/inbox -type f | xargs ls -l
couchbase-cli ssl-manage -c 127.0.0.1 -u Administrator -p password --set-node-certificate
sleep 3s
