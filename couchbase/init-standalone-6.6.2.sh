#!/bin/bash
set -e
set -x
echo '/*** server start-up ***/'
sleep 20s
echo '/*** init cluster ***/'
cd /tmp
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
echo '/*** cluster root CA ***/'
cd /tmp
openssl genrsa -out /tmp/ca.key 2048
openssl req -new -x509 -days 3650 -sha256 -key /tmp/ca.key -out /tmp/ca.pem \
-subj "/CN=Couchbase Cluster CA/OU=Engineering/O=Wibmo/L=Bangalore/ST=Karnataka/C=IN"
openssl x509 -subject -issuer -startdate -enddate -noout -in /tmp/ca.pem
openssl rsa -check -noout -in /tmp/ca.key
openssl rsa -modulus -noout -in /tmp/ca.key | openssl md5
openssl x509 -modulus -noout -in /tmp/ca.pem | openssl md5 # value must match with previous command
echo '/*** node cert. ***/'
cd /tmp
cat > /tmp/node.ext <<EOF
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
extendedKeyUsage=serverAuth
keyUsage=digitalSignature,keyEncipherment
subjectAltName=IP:127.0.0.1
EOF
openssl genrsa -out /tmp/pkey.key 2048
openssl req -new -key /tmp/pkey.key -out /tmp/node.csr \
-subj "/CN=Couchbase Node/OU=Engineering/O=Wibmo/L=Bangalore/ST=Karnataka/C=IN"
openssl x509 -CA /tmp/ca.pem -CAkey /tmp/ca.key -CAcreateserial -days 365 -req \
-in /tmp/node.csr \
-out /tmp/chain.pem \
-extfile /tmp/node.ext
openssl x509 -subject -issuer -startdate -enddate -noout -in ./chain.pem
openssl rsa -check -noout -in ./pkey.key
openssl rsa -modulus -noout -in ./pkey.key | openssl md5
openssl x509 -modulus -noout -in ./chain.pem | openssl md5
echo '/*** update certs. ***/'
# update cluster root cert.
couchbase-cli ssl-manage -c 127.0.0.1 -u Administrator -p password --upload-cluster-ca /tmp/ca.pem
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
echo '/*** create bucket with data ***/'
couchbase-cli bucket-create \
                --cluster localhost \
                --username Administrator \
                --password password \
                --bucket default \
                --bucket-type couchbase \
                --bucket-ramsize 256
sleep 3s
cbimport    csv \
            -c localhost \
            -u Administrator \
            -p password \
            -b default \
            -d file:///app/config/data.csv \
            -g key::#MONO_INCR#
sleep 3s
cbq -u Administrator -p password -script 'create primary index `#primary` ON `default`;'
sleep 3s
cbq -u Administrator -p password -script '
select min(d0.yyyymmdd) as earliest 
    from ( 
        select d1.yyyymmdd, d1.ip 
        from `default` d1 
        where d1.cardNo in ( 
            select raw d2.cardNo 
            from `default` d2 
            where d2.clientId = "5") 
    ) d0 
    where d0.ip in ( 
            select raw d3.ip 
            from `default` d3 
            where d3.clientId = "5");'
