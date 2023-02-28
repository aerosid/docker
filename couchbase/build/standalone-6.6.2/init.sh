#!/bin/bash
set -e
set -x
# create couchbase cluster
couchbase-cli   cluster-init \
                --cluster-username Administrator \
                --cluster-password password \
                --cluster-name Default \
                --services data,index,analytics,eventing \
                --cluster-ramsize 256 \
                --cluster-index-ramsize 256 \
                --cluster-analytics-ramsize 1024 \
                --cluster-eventing-ramsize 256 \
                --index-storage-setting default
couchbase-cli reset-admin-password --new-password password
# update cluster root cert.
couchbase-cli ssl-manage -c 127.0.0.1 -u Administrator -p password --upload-cluster-ca /app/config/ca.pem
# update node cert.
mkdir -p /opt/couchbase/var/lib/couchbase/inbox
cp /app/config/chain.pem /opt/couchbase/var/lib/couchbase/inbox/chain.pem
cp /app/config/pkey.key /opt/couchbase/var/lib/couchbase/inbox/pkey.key
chown -R couchbase:couchbase /opt/couchbase/var/lib/couchbase/inbox
chmod +x /opt/couchbase/var/lib/couchbase/inbox
chmod 0600 /opt/couchbase/var/lib/couchbase/inbox/*
find /opt/couchbase/var/lib/couchbase/inbox -type f | xargs ls -l
couchbase-cli ssl-manage -c 127.0.0.1 -u Administrator -p password --set-node-certificate