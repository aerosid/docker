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
--hsts-max-age 43200 \
--hsts-preload-enabled 1 \
--hsts-include-sub-domains-enabled 1
couchbase-cli setting-security \
-c 127.0.0.1:8091 \
-u Administrator \
-p password \
--set \
--tls-min-version tlsv1.2

