#!/bin/bash
set -e
set -x
couchbase-cli setting-autofailover \
-c http://127.0.0.1:8091 \
-u Administrator \
-p password \
--enable-auto-failover 0
sleep 3s

couchbase-cli node-to-node-encryption \
-c couchbase://localhost \
-u Administrator \
-p password \
--enable
sleep 3s

couchbase-cli setting-security \
-c http://127.0.0.1:8091 \
-u Administrator \
-p password \
--set \
--cluster-encryption-level all
sleep 3s

couchbase-cli setting-autofailover \
-c 127.0.0.1:8091 \
-u Administrator \
-p password \
--enable-auto-failover 1 \
--auto-failover-timeout 120 \
--enable-failover-of-server-groups 0 \
--max-failovers 1 \
--can-abort-rebalance 1
sleep 3s

couchbase-cli node-to-node-encryption \
-c http://127.0.0.1:8091 \
-u Administrator \
-p password \
--get
sleep 3s

couchbase-cli setting-security \
-c 127.0.0.1:8091 \
-u Administrator \
-p password \
--set \
--tls-min-version tlsv1.2 
sleep 3s

couchbase-cli setting-security \
-c 127.0.0.1:8091 \
-u Administrator \
-p password \
--get
sleep 3s

couchbase-cli bucket-create \
-c 127.0.0.1:8091 \
-u Administrator \
-p password \
--bucket default \
--bucket-type couchbase \
--bucket-ramsize 256
sleep 3s

cbimport csv \
-c 127.0.0.1:8091 \
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