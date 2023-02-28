#!/bin/bash
set -e
set -x
echo '/*** init cluster ***/'
cd /tmp
sleep 3s
couchbase-cli cluster-init \
                --cluster-username Administrator \
                --cluster-password password \
                --cluster-name Default \
                --services data,index,query \
                --cluster-ramsize 256 \
                --cluster-index-ramsize 256 \
                --index-storage-setting default
sleep 3s
couchbase-cli reset-admin-password --new-password password
sleep 3s
couchbase-cli server-add \
                --cluster 10.229.214.131 \
                --username Administrator \
                --password password \
                --server-add http://10.229.214.132:8091 \
                --server-add-username Administrator \
                --server-add-password password \
                --services data
sleep 3s
couchbase-cli server-add \
                --cluster 10.229.214.131 \
                --username Administrator \
                --password password \
                --server-add http://10.229.214.133:8091 \
                --server-add-username Administrator \
                --server-add-password password \
                --services data
sleep 3s
couchbase-cli rebalance \
                --cluster 10.229.214.131 \
                --username Administrator \
                --password password
sleep 3s
couchbase-cli bucket-create \
                --cluster localhost \
                --username Administrator \
                --password password \
                --bucket delete-me \
                --bucket-type couchbase \
                --bucket-ramsize 256
echo '/*** cluster root CA ***/'
cd /app/config
openssl genrsa -out /app/config/ca.key 2048
openssl req -new -x509 -days 3650 -sha256 -key /app/config/ca.key -out /app/config/ca.pem \
-subj "/CN=Couchbase Cluster CA/OU=Engineering/O=Wibmo/L=Bangalore/ST=Karnataka/C=IN"
openssl x509 -subject -issuer -startdate -enddate -noout -in /app/config/ca.pem
openssl rsa -check -noout -in /app/config/ca.key
openssl rsa -modulus -noout -in /app/config/ca.key | openssl md5
openssl x509 -modulus -noout -in /app/config/ca.pem | openssl md5 # value must match with previous command
echo '/*** node cert. ***/'
cd /tmp
cat > /tmp/node.ext <<EOF
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
extendedKeyUsage=serverAuth
keyUsage=digitalSignature,keyEncipherment
subjectAltName=IP:10.229.214.131
EOF
openssl genrsa -out /tmp/pkey.key 2048
openssl req -new -key /tmp/pkey.key -out /tmp/node.csr \
-subj "/CN=Couchbase Node 131/OU=Engineering/O=Wibmo/L=Bangalore/ST=Karnataka/C=IN"
openssl x509 -CA /app/config/ca.pem -CAkey /app/config/ca.key -CAcreateserial -days 365 -req \
-in /tmp/node.csr \
-out /tmp/chain.pem \
-extfile /tmp/node.ext
openssl x509 -subject -issuer -startdate -enddate -noout -in ./chain.pem
openssl rsa -check -noout -in ./pkey.key
openssl rsa -modulus -noout -in ./pkey.key | openssl md5
openssl x509 -modulus -noout -in ./chain.pem | openssl md5
echo '/*** update certs. ***/'
# update cluster root cert.
couchbase-cli ssl-manage -c 10.229.214.131 -u Administrator -p password --upload-cluster-ca /app/config/ca.pem
sleep 3s
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
