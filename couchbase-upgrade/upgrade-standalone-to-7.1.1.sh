#!/bin/bash
set -e
set -x
cd /tmp
couchbase-server --stop && echo "success" || echo "failed"
sleep 10s
couchbase-server --status && echo "success"  || echo "failed"
# See https://docs.couchbase.com/server/current/install/upgrade-cluster-online-full-capacity.html
cp -r /opt/couchbase/var/lib/couchbase/config /tmp/config-backup # backup config files
apt autoremove -y --purge couchbase-server # uninstall on ubuntu
rm -rf /opt/couchbase && echo "success" || echo "failed"
ls -l /opt/couchbase/var
apt update
apt install -y curl lsb-release gnupg2
curl -O https://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-amd64.deb # meta-package
dpkg -i ./couchbase-release-1.0-amd64.deb
apt-get update
apt list -a couchbase-server
apt-get install -y couchbase-server=7.1.1-3175-1
couchbase-server --start && echo "success" || echo "failed"
sleep 10s
couchbase-server --status && echo "success" || echo "failed"
mkdir -p /opt/couchbase/var/lib/couchbase/inbox/CA
cp /tmp/ca.pem /opt/couchbase/var/lib/couchbase/inbox/CA
cp /tmp/chain.pem /opt/couchbase/var/lib/couchbase/inbox/chain.pem
cp /tmp/pkey.key /opt/couchbase/var/lib/couchbase/inbox/pkey.key
chown -R couchbase:couchbase /opt/couchbase/var/lib/couchbase/inbox
chmod +x /opt/couchbase/var/lib/couchbase/inbox
chmod 0600 /opt/couchbase/var/lib/couchbase/inbox/*
find /opt/couchbase/var/lib/couchbase/inbox -type f | xargs ls -l
couchbase-cli   ssl-manage \
                -c localhost \
                -u Administrator \
                -p password \
                --cluster-ca-load
sleep 3s
couchbase-cli   ssl-manage \
                -c localhost \
                -u Administrator \
                -p password \
                --set-node-certificate
sleep 3s
couchbase-cli   cluster-init \
                --cluster-username Administrator \
                --cluster-password password \
                --cluster-name Default \
                --services data,index,query \
                --cluster-ramsize 256 \
                --cluster-index-ramsize 256 \
                --index-storage-setting default
sleep 3s
couchbase-cli   bucket-create \
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