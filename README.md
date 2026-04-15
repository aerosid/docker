# README
```bash
# batch.sh will hold a bunch of commands to run in one go.
touch ~/batch.sh && chmod +x ~/batch.sh
```
## 1. Asterisk
Installation:
```bash
apt update 
apt upgrade -y
apt install -y tree vim wget build-essential # build-essential holds the C++ compiler
which gcc
which g++
# Download Source
cd /tmp
wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-22-current.tar.gz
tar -tvzf /tmp/asterisk-22-current.tar.gz
tar -C /usr/local/src -xvzf /tmp/asterisk-22-current.tar.gz
# Install Pre-reqs
cd /usr/local/src/asterisk-22.8.2
apt-get update
cd ./contrib/scripts
./install_prereq test # run apt-get update again if you need to
./install_prereq install
# Validate Pre-reqs
cd /usr/local/src/asterisk-22.8.2
make distclean
./configure
# Build
make menuselect
make #compile asterisk
# Install
make install #install asterisk
make samples #/etc/asterisk/*.conf
make config #/etc/init.d/asterisk
make install-logrotate
make basic-pbx
make progdocs
```
Sample `pjsip.conf`:
```ini
[airtel-udp]
type=transport
protocol=udp
bind=192.168.6.3
local_net=192.168.6.0/24

[wireguard-udp]
type=transport
protocol=udp
bind=10.0.0.2

[fxo]
type=auth
auth_type=userpass
username=fxo
password=hello

[fxo]
type=endpoint
transport=airtel-udp
context=wan
disallow=all
allow=ulaw
auth=fxo ; inbound, i.e., fxo calls asterisk
outbound_auth=fxo ; outbound, i.e., asterisk calls fxo
aors=fxo
force_rport=yes
rtp_symmetric=yes
direct_media=yes
rewrite_contact=yes ; without this setting, audio does not work
rtp_keepalive=1 ; without this setting, audio does not work

[fxo]
type=aor
contact=sip:192.168.6.65:5062
qualify_frequency=300
max_contacts=1

[fxo]
type=identify
endpoint=fxo
match=192.168.6.65

[aws-asterisk]
type=endpoint
transport=wireguard-udp
context=wan
disallow=all
allow=ulaw
aors=aws-asterisk
force_rport=yes
rtp_symmetric=yes
direct_media=no ; when set to yes, strict RTP learning does not complete; but audio is available

[aws-asterisk]
type=aor
contact=sip:10.0.0.1
qualify_frequency=300
max_contacts=1

[aws-asterisk]
type=identify
endpoint=aws-asterisk
match=10.0.0.1
```
Sample `extensions.conf`:
```ini
[wan]
; Inbound call: customer calling application
; When FXO calls airtel-asterisk, it auto-dials extension 2
exten => 2,1,NoOp(Inbound call: customer calling application at +917795774476)
exten => 2,n,Dial(PJSIP/+14808004695@aws-asterisk)
exten => 2,n,Hangup()


; Outbound call: application calling customer
; aws-asterisk dialed +91XXXXXXXXXX
exten => _+91.,1,NoOp(Outbound call: application calling customer at ${EXTEN})
exten => _+91.,n,Dial(PJSIP/${EXTEN:3}@fxo)
exten => _+91.,n,Hangup()
```
See: [Doc](https://docs.asterisk.org/)
1. Basic Commands:
```
start, remote console: https://docs.asterisk.org/Operation/Running-Asterisk/
stop: https://docs.asterisk.org/Operation/Running-Asterisk/Stopping-and-Restarting-Asterisk-From-The-CLI/
reload config: core reload
help: core show help
```
2. /etc/asterisk/pjsip.conf:
```
Configuration File Format: https://docs.asterisk.org/Configuration/Channel-Drivers/SIP/Configuring-res_pjsip/PJSIP-Configuration-Sections-and-Relationships/
Configuration Options: https://docs.asterisk.org/Latest_API/API_Documentation/Module_Configuration/res_pjsip/
```
3. /etc/asterisk/extensions.conf:
```
Configuration File Format: https://docs.asterisk.org/Configuration/Dialplan/Contexts-Extensions-and-Priorities/
Useful Applications: https://docs.asterisk.org/Configuration/Applications/Answer-Playback-and-Hangup-Applications/
Useful Applications: https://docs.asterisk.org/Configuration/Applications/Dial-Application/
```
4. Application Reference: https://docs.asterisk.org/Asterisk_22_Documentation/API_Documentation/Dialplan_Applications/

5. Function Reference: https://docs.asterisk.org/Asterisk_22_Documentation/API_Documentation/Dialplan_Functions/

7. Global Variables Reference: https://docs.asterisk.org/Configuration/Dialplan/Variables/


## 2. cAdvisor
```bash
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
docker pull gcr.io/cadvisor/cadvisor:v0.45.0
docker tag gcr.io/cadvisor/cadvisor:v0.45.0 cadvisor:latest
docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  cadvisor:latest
EOF
```
## 3. Couchbase
See:
- [Multi-node, Single Host Cluster](https://docs.couchbase.com/server/current/install/getting-started-docker.html#multi-node-cluster-one-host)
- [Server Certificates](https://docs.couchbase.com/server/current/manage/manage-security/manage-security-settings.html#root-certificate-security-screen-display)
- [Configure Sever Certificates](https://docs.couchbase.com/server/current/manage/manage-security/configure-server-certificates.html)
- [On-the-Wire Security](https://docs.couchbase.com/server/current/manage/manage-security/manage-tls.html)
- tls-cluster-7.1.1.yml
## 4. Docker
### 4.1. Standard
```bash
# install docker
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
sudo apt install -y curl gnupg software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli
sudo usermod -a -G docker $(whoami)
EOF
~/batch.sh

# configure docker
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
sudo tee /etc/docker/daemon.json <<EOFF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOFF
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
EOF
~/batch.sh
```
### 4.2. Rootless
- See [Rootless Docker](https://docs.docker.com/engine/security/rootless/)

First, deploy standard.
```bash
sudo apt-get install -y uidmap
apt list uidmap
grep ^$(whoami): /etc/subuid
grep ^$(whoami): /etc/subgid
apt list dbus-user-session

sudo systemctl disable --now docker.service docker.socket
sudo reboot
# log back in
dockerd-rootless-setuptool.sh install
systemctl --user enable docker
sudo loginctl enable-linger $(whoami)
```
### 4.3. WSL 
Start Docker
```
/mnt/c/Windows/System32/wsl.exe -d Ubuntu sh -c "nohup sudo -b dockerd >/home/ubuntu/dockerd.log 2>&1 </dev/null"
# -d: WSL distro to run
# nohup: keep running whether or not connection is lost or you logout
# -b: attach containers to network bridge
# >/home/ubuntu/dockerd.log: redirect stdout to dockerd.log
# 2>&1: redirect stderr to stdout
# </dev/null: don't expect input
```
Stop Docker
```
sudo kill -SIGTERM $(pidof dockerd)
```

## 5. Envoy
```bash
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
docker pull envoyproxy/envoy:v1.23.1
docker tag envoyproxy/envoy:v1.23.1 envoy:latest
mkdir -p ~/docker/envoy/config
tee ~/docker/envoy/config/envoy.yaml <<EOFF
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        address: 0.0.0.0
        port_value: 10000
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: edge
          http_filters:
          - name: envoy.filters.http.router
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
          route_config:
            virtual_hosts:
            - name: direct_response_service
              domains: ["*"]
              routes:
              - match:
                  prefix: "/"
                route:
                  cluster: nginx
  clusters:
  - name: nginx
    connect_timeout: 5s
    load_assignment:
      cluster_name: nginx
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 80
EOFF
docker  run \
        -d \
        --name envoy \
        --network host \
        --rm \
        -v ~/docker/envoy/config/envoy.yaml:/etc/envoy/envoy.yaml:ro \
        envoy:latest
EOF
~/batch.sh
```
## 6. Fluentd
See
- [Docker Hub](https://hub.docker.com/r/fluent/fluentd/)
- [Fluentd Configuration](https://docs.fluentd.org/configuration/config-file)
- [Fluentd-Loki](https://grafana.com/docs/loki/latest/clients/fluentd/)
```bash
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
sudo tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
mkdir -p ~/docker/fluentd/build
mkdir -p ~/docker/fluentd/config
mkdir -p ~/docker/fluentd/log
tee ~/docker/fluentd/build/Dockerfile <<EOFF
FROM fluent/fluentd:v1.15.0-1.0
USER root
RUN fluent-gem install fluent-plugin-grafana-loki && fluent-gem install fluent-plugin-prometheus
USER fluent
EOFF
cd ~/docker/fluentd/build
docker build -t fluentd:latest .
cd ~
tee ~/docker/fluentd/config/fluentd.config <<EOFF
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>
<source>
  @type tail
  path /var/log/fluentd.log
  tag *
  <parse>
    @type none
  </parse>
</source>
<match **>
  @type copy
  <store>
    @type loki
    url "http://127.0.0.1:3100"
    extra_labels {"logger":"fluentd"}
    flush_interval 2s
    flush_at_shutdown true
    buffer_chunk_limit 1k
    insecure_tls true
  </store>
  <store>
    @type stdout
  </store>
</match>
EOFF
tee ~/docker/fluentd/run.sh <<EOFF
docker  run \\
        -d \\
        --name fluentd \\
        --network=host \\
        --rm \\
        --user $(id -u):$(id -g) \\
        -v ~/docker/fluentd/config:/fluentd/etc \\
        -v ~/nifty/console.log:/var/log/fluentd.log \\
        -v ~/docker/fluentd/log:/fluentd/log \\
        fluentd:latest -c /fluentd/etc/fluentd.config
EOFF
chmod +x ~/docker/fluentd/run.sh
~/docker/fluentd/run.sh
EOF
~/batch.sh
```

## 7. Git
```bash
cd C:\Users\sidharth.sankar\Downloads
git clone https://host/repo/repo.git trunk
cd trunk
git branch -a #list all branches in repository
git checkout -b develop origin/develop #checkout remote branch develop
git branch
cd ..\feature
git branch -a
git checkout -b develop origin/develop
git branch
cd ..\trunk
git checkout -b trunk master #create new local branch, trunk, as a clone of local branch, master
git push -u origin trunk #push local branch, trunk, to remote repo.
git add ... git commit ... git push #make three commits, 1, 2, and 3, on new file sample.txt
git checkout -b feature trunk #create new local branch, feature, as a clone of local branch, trunk
git push -u origin feature #push local branch, feature, to remote repo. named origin

cd ..\feature
git fetch --all
git branch -r
git checkout -b feature origin/feature #checkout remote branch feature
git add ... git commit ... git push #make two commits, a, and b, on file, sample.txt

cd ..\trunk
git checkout trunk
git add ... git commit ... git push #make one commit, 4 on file, sample.txt

cd ..\feature
git fetch --all
git branch -r
git checkout -b trunk origin/trunk

git reset --soft 8a1d54a
git stash push -m 'b'
git stash list

git reset --soft fd82c78
git stash push -m 'a'
git stash list

git checkout feature
git merge trunk

git stash pop 'stash@{0}' #Fix merge conflicts
git add
git commit -m 'a' #Don't push to remote
git stash pop 'stash@{1}' #Fix merge conflicts
git add
git commit -m 'b' #Don't push to remote

git push --force

git checkout trunk
git merge feature
```
## 8. Grafana
See, (Nginx Reverse Proxy)[https://grafana.com/tutorials/run-grafana-behind-a-proxy/]
```bash
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
mkdir -p ~/docker/grafana/build
mkdir -p ~/docker/grafana/lib
mkdir -p ~/docker/grafana/log
mkdir -p ~/docker/grafana/provisioning
mkdir -p ~/docker/grafana/provisioning/datasources
mkdir -p ~/docker/grafana/provisioning/plugins
mkdir -p ~/docker/grafana/provisioning/notifiers
mkdir -p ~/docker/grafana/provisioning/alerting
mkdir -p ~/docker/grafana/provisioning/dashboards
docker pull grafana/grafana:latest
docker tag grafana/grafana:latest grafana:latest
tee ~/docker/grafana/run.sh <<EOFF
docker  run \\
        -d \\
        --name=grafana \\
        --network=host \\
        --rm \\
        --user $(id -u):$(id -g) \\
        -v ~/docker/grafana/lib:/var/lib/grafana \\
        -v ~/docker/grafana/log:/var/log/grafana \\
        -v ~/docker/grafana/provisioning:/etc/grafana/provisioning \\
        -v ~/docker/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources \\
        -v ~/docker/grafana/provisioning/plugins:/etc/grafana/provisioning/plugins \\
        -v ~/docker/grafana/provisioning/notifiers:/etc/grafana/provisioning/notifiers \\
        -v ~/docker/grafana/provisioning/alerting:/etc/grafana/provisioning/alerting \\
        -v ~/docker/grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards \\
        grafana:latest
EOFF
chmod +x ~/docker/grafana/run.sh
~/docker/grafana/run.sh
EOF
~/batch.sh
```
```bash
GF_PATHS_DATA=/var/lib/grafana
GF_PATHS_LOGS=/var/log/grafana
GF_PATHS_PLUGINS=/var/lib/grafana/plugins
GF_PATHS_PROVISIONING=/etc/grafana/provisioning
```

## 9. IpTables
* [Order of Tables and Chains](https://share.google/aimode/m9gzz0SbG43lriozO)

1. Chain (packet traversal) order: PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING
2. Table order: Raw, Mangle, NAT, Filter (default; i.e. when the -t option is not provided), Security
3. Table-Chain order: 
    * PREROUTING: Raw, Mangle, NAT (DNAT)
    * INPUT: Mangle, Filter, Security, NAT
    * FORWARD: Mangle, Filter, Security
    * OUTPUT: Raw, Mangle, NAT, Filter, Security
    * POSTROUTING: Mangle, NAT (SNAT)

## 10. Loki
See
- [Loki Configuration](https://grafana.com/docs/loki/latest/configuration/)
```bash
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
mkdir -p ~/docker/loki/config
mkdir -p ~/docker/loki/data
tee ~/docker/loki/config/local-config.yaml <<EOFF
auth_enabled: false
server:
  http_listen_port: 3100
common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory
schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h
ruler:
  alertmanager_url: http://localhost:9093
EOFF
docker pull grafana/loki:latest
docker tag grafana/loki:latest loki:latest
tee ~/docker/loki/run.sh <<EOFF
docker  run \\
        -d \\
        --name=loki \\
        --network=host \\
        --rm \\
        --user $(id -u):$(id -g) \\
        -v ~/docker/loki/config/local-config.yaml:/etc/loki/local-config.yaml \\
        -v ~/docker/loki/data:/loki \\
        loki:latest
EOFF
chmod +x ~/docker/loki/run.sh
~/docker/loki/run.sh
sleep 10s
curl http://localhost:3100/ready
EOF
~/batch.sh
```

```bash
# Log using HTTP API
EPOCHNANO=$(date +%s)000000000
echo $EPOCHNANO
curl  -v \
      -H "Content-Type: application/json" \
      -X POST -s "http://localhost:3100/loki/api/v1/push" \
      --data-raw '{"streams": [{ "stream": { "logger": "shell" }, "values": [ [ "1662950083000000000", "This is a test" ] ] }]}'
```

## 11. Minio
- [Installing Minio](https://linuxhint.com/installing_minio_ubuntu/)
- [Minio Server](https://min.io/docs/minio/linux/reference/minio-server/minio-server.html#)
- [Minio Client](https://min.io/docs/minio/linux/reference/minio-mc.html)
- [download_from_minio.sh](https://gist.github.com/JustinTimperio/ae695eef5fda1f1590a685a017bbb5ec#file-download_from_minio-sh-L50)
```bash

docker pull bitnami/minio:latest
docker run \
--detach \
--env MINIO_ROOT_USER="minio-root-user" \
--env MINIO_ROOT_PASSWORD="minio-root-password" \
--name minio \
--network host \
--rm \
--volume /home/ubuntu/vscode/docker/minio:/app:rw \
bitnami/minio:latest
docker exec -it minio /bin/bash
cd /tmp
mc alias set localhost http://127.0.0.1:9000 "minio-root-user" "minio-root-password"
mc admin info localhost
mc mb -p localhost/tmp
echo "Hello World!" > message.txt
mc cp ./message.txt localhost/tmp
mc cat localhost/tmp/message.txt
mc cp localhost/tmp/message.txt ./message.bak.txt
cat ./message.bak.txt
md5sum /tmp/message.txt /tmp/message.bak.txt | md5sum --check
/app/download.sh
```

## 12. Nginx
```bash
cat <<EOT >> greetings.txt
line 1
line 2
EOT

tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
docker pull nginx:1.23.1
docker tag nginx:1.23.1 nginx:latest
mkdir -p ~/docker/nginx/www
echo '<html><head><title>index</title></head><body>Hello World!</body></html>' > ~/docker/nginx/www/index.html
docker  run \\
        -d \\
        --name nginx \\
        --network host \\
        --rm \\
        -v ~/docker/nginx/www:/usr/share/nginx/html:ro \\
        nginx:latest
EOF
~/batch.sh
```
```bash
mkdir -p ~/docker/nginx/config
tee ~/docker/nginx/config/default.conf<<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;
events {
    worker_connections 1024;
}
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    log_format main '\$status    \$remote_addr    \$request    \$http_user_agent';
    access_log /var/log/nginx/access.log  main;
    sendfile on;
    keepalive_timeout 65;
    server {
        listen 80;
        listen [::]:80;
        server_name localhost;
        location / {
            root  /usr/share/nginx/html;
            index index.html;
        }
    }
    server {
        listen 443 ssl;
        listen [::]:443 ssl; # For IPv6 support
        server_name localhost;
        ssl_certificate /etc/nginx/ssl/nginx.crt; # Path to your SSL certificate
        ssl_certificate_key /etc/nginx/ssl/nginx.key; # Path to your private key
            location / {
                root /usr/share/nginx/html;
                index index.html;
            }
    }
}
EOF
tee ~/docker/nginx/config/simple.conf<<EOF
upstream backend {
  server localhost:8001;
}
server {
  listen 80;
  server_name localhost;
  location / {
    proxy_pass http://backend;
  }
}
EOF
tee ~/docker/nginx/run.sh<<EOF
docker  run \\
        -d \\
        --name nginx \\
        --network host \\
        --rm \\
        -v ~/docker/nginx/www:/usr/share/nginx/html:ro \\
        -v ~/docker/nginx/config/default.conf:/etc/nginx/nginx.conf:ro \\
        nginx:latest
EOF
```
## 13. OpenSSL
```bash
cd /app/config

# Self-signed certificate
openssl genrsa -out /app/config/ca.key 2048 # create private key
openssl rsa -check -noout -in /app/config/ca.key # validate key

openssl req -new -x509 -days 3650 -sha256 -key /app/config/ca.key -out /app/config/ca.pem \
-subj "/CN=Couchbase Cluster CA/OU=Engineering/O=CA Authority/L=Bangalore/ST=Karnataka/C=IN" # create self-signed cert.
openssl x509 -subject -issuer -startdate -enddate -noout -in /app/config/ca.pem # validate cert.

openssl rsa -modulus -noout -in /app/config/ca.key | openssl md5
openssl x509 -modulus -noout -in /app/config/ca.pem | openssl md5 # match private key with cert; md5 sums must match

# Certificate from CSR and extension
openssl genrsa -out /app/config/acme.key 2048 # private key
openssl rsa -check -noout -in /app/config/acme.key # validate key

cat > /app/config/acme.ext <<EOF
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
extendedKeyUsage=serverAuth
keyUsage=digitalSignature,keyEncipherment
subjectAltName=IP:10.229.214.131
EOF # create certificate extension
openssl req -new -key /app/config/acme.key -out /app/config/acme.csr \
-subj "/CN=Couchbase Node 131/OU=Engineering/O=Acme/L=Bangalore/ST=Karnataka/C=IN" # create csr
openssl x509 -CA /app/config/ca.pem -CAkey /app/config/ca.key -CAcreateserial -days 365 -req \
-in /app/config/acme.csr \
-out /app/config/acme.pem \
-extfile /app/config/acme.ext # create cert. from csr and extension (extension is optional)
openssl x509 -subject -issuer -startdate -enddate -noout -in /app/config/acme.pem # validate cert.

openssl rsa -modulus -noout -in /app/config/acme.key | openssl md5
openssl x509 -modulus -noout -in /app/config/acme.pem | openssl md5 # match private key with cert; md5 sums must match
```
## 14. Portainer
See
- [Portainer Deployment](https://docs.portainer.io/v/ce-2.9/start/install/server/docker/linux)

```bash
docker pull portainer/portainer-ce
docker tag portainer/portainer-ce portainer:latest
mkdir -p ~/docker/portainer/data

tee ~/docker/portainer/run.sh <<EOF
#!/bin/bash
docker run \\
  --detach \\
  --name portainer \\
  --publish 9001:9000 \\
  --rm \\
  --volume /var/run/docker.sock:/var/run/docker.sock \\
  --volume portainer_data:/data \\
  portainer:latest
EOF
chmod +x ~/docker/portainer/run.sh
# password: A8(k*2S*muxM
```
## 15. Prometheus
- [Loki Configuration](https://grafana.com/docs/loki/latest/configuration/)
```bash
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
mkdir -p ~/docker/prometheus/config
tee ~/docker/prometheus/config/prometheus.yml <<EOFF
EOFF
docker pull prom/prometheus:v2.38.0
docker tag prom/prometheus:v2.38.0 prometheus:latest
docker run --it --name prometheus --network=host --rm prometheus:latest
```
Open `localhost:9090`.
## 16. RabbitMQ
```bash
# Create rabbit-mq network
docker network create \
  --driver=bridge \
  --subnet=10.229.213.0/24 \
  --ip-range=10.229.213.0/24 \
  --gateway=10.229.213.1 \
  hdfc-213
docker network create \
  --driver=bridge \
  --subnet=10.229.214.0/24 \
  --ip-range=10.229.214.0/24 \
  --gateway=10.229.214.1 \
  hdfc-214  

docker run \
  -d \
  --network hdfc-uat \
  --hostname rabbit-217 \
  --ip 10.229.213.217 \
  --name rabbit-217 \
  -p 15672:15672 \
  --rm \
  -v ~/frm-cloud/docker/rabbitmq/config/rabbitmq-cluster.conf:/etc/rabbitmq/rabbitmq.conf:ro \
  -v ~/frm-cloud/docker/rabbitmq/config/host.pem:/etc/rabbitmq/rabbitmq.crt:ro \
  -v ~/frm-cloud/docker/rabbitmq/config/host.key:/etc/rabbitmq/rabbitmq.key:ro \
  rabbitmq:cluster

docker run \
  -d \
  --network hdfc-uat \
  --hostname rabbit-218 \
  --ip 10.229.213.218 \
  --name rabbit-218 \
  --rm \
  -v ~/frm-cloud/docker/rabbitmq/config/rabbitmq-cluster.conf:/etc/rabbitmq/rabbitmq.conf:ro \
  -v ~/frm-cloud/docker/rabbitmq/config/host.pem:/etc/rabbitmq/rabbitmq.crt:ro \
  -v ~/frm-cloud/docker/rabbitmq/config/host.key:/etc/rabbitmq/rabbitmq.key:ro \
  rabbitmq:cluster
```
## 17. Redis
```bash
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
docker pull redis:7.0.4
docker tag redis:7.0.4 redis:latest
docker  run \
        -d \
        --name redis \
        --rm \
        redis:latest
EOF
~/batch.sh
```
```bash
# run redis-cli
docker  run \
        -it \
        --name redis-cli \
        --network host \
        --rm \
        redis:latest redis-cli -h 127.0.0.1
```

## 18. SonarQube
See
- [SonarQube Documentation](https://docs.sonarqube.org/latest/)
- [Disable Rules](https://sqa.stackexchange.com/questions/24734/how-to-deactivate-a-rule-in-sonarqube)
```bash
docker pull sonarqube:developer
docker tag sonarqube:developer sonarqube:latest
mkdir -p ~/docker/sonarqube/config ~/docker/sonarqube/data ~/docker/sonarqube/logs ~/docker/sonarqube/extensions

tee ~/docker/sonarqube/config/config.sh <<EOF
#!/bin/bash
set -e
set -x
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
EOF
chmod +x ~/docker/sonarqube/config/config.sh

tee ~/docker/sonarqube/run.sh<<EOF
#!/bin/bash
set -e
set -x
docker run \\
-d \\
-e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \\
--name sonarqube \\
--publish 9000:9000 \\
--rm \\
--stop-timeout 3600 \\
-v ~/docker/sonarqube/data:/opt/sonarqube/data \\
-v ~/docker/sonarqube/logs:/opt/sonarqube/logs \\
-v ~/docker/sonarqube/extensions:/opt/sonarqube/extensions \\
--user $(id -u):$(id -g) \\
sonarqube:latest
EOF
chmod +x ~/docker/sonarqube/run.sh

# UI
Analyze "TridentCSR": sqp_3d262afd0b532120248e38f0de020c52b182db42

squ_5ee74580b7c2631c7e0363a851bfccf839b546a8

plugins {
  id "org.sonarqube" version "3.4.0.2513"
}

C:\Users\sidharth.sankar\AppData\Local\gradle-5.4.1\bin\gradle.bat sonarqube `
  -Dsonar.projectKey=TridentCSR `
  -Dsonar.host.url=http://localhost:9000 `
  -Dsonar.login=squ_5ee74580b7c2631c7e0363a851bfccf839b546a8 `
  -Dsonar.login=sqp_3d262afd0b532120248e38f0de020c52b182db42
```
## 19. Ubuntu
```bash
tee ~/batch.sh<<EOF
#!/bin/bash
set -e
set -x
mkdir -p ~/docker/ubuntu/build
tee ~/docker/ubuntu/build/Dockerfile <<EOFF
FROM ubuntu:20.04
RUN addgroup --gid $(id -g ubuntu) ubuntu \
&& addgroup --gid $(ls -ldn /var/run/docker.sock | awk '{print $4}') docker \
&& adduser --disabled-password --gecos "" --gid $(id -g ubuntu) --uid $(id -u ubuntu) ubuntu \
&& adduser ubuntu docker \
&& apt update \
&& apt install -y sqlite3 \
&& ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
USER ubuntu:ubuntu
WORKDIR /home/ubuntu/nifty
EOFF
cd ~/docker/ubuntu/build
docker build -t ubuntu:latest .
cd ~
docker run -it --name focal --network=host --rm -v ~:/home/ubuntu ubuntu:latest sqlite3 --version
EOF
```
Sample log message:
```bash
docker  run \
        --log-driver=fluentd \
        --log-opt fluentd-address=127.0.0.1:24224 \
        --log-opt tag="{{.Name}}" \
        --log-opt mode=non-blocking \
        --log-opt max-buffer-size=1k \
        --name focal \
        --network="host" \
        --rm \
        -v ~:/home/ubuntu ubuntu echo 'Hello World!' $(date)
```
### 19.1. Swap Space
```bash
sudo swapon --show # shows current active swap partitions
sudo fallocate -l 2G /swapfile # creates 2G swap in file /swapfile
sudo chmod 600 /swapfile # restrict access to /swapfile
sudo mkswap /swapfile # initializes swap space
sudo swapon /swapfile # activates swap space
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab # mounts /swapfile on reboot
sudo mount -a # verifies integrity of /etc/fstab
sudo findmnt --verify --verbose # a more comprehensive verification of /etc/fstab
```

## 20. UFW
### 20.1. Installation
```
ufw status
sudo apt install -y ufw
sudo systemctl start ufw 
sudo systemctl enable ufw
sudo systemctl status ufw
```
### 20.2. SSH
```
ufw status # expect Status: inactive
sudo ufw allow OpenSSH 
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw show added

sudo ufw enable
ufw status
```
### 20.3. Web
```
sudo ufw allow http 
sudo ufw allow https
sudo ufw show added
ufw status
```
### 20.4 Port Forwarding
Refer: [UFW Port Forwarding](https://www.baeldung.com/linux/ufw-port-forward)

#### 20.4.1. Update `sysctl.conf`
```
cat /etc/ufw/sysctl.conf
echo 'net/ipv4/ip_forward=1' >> /etc/ufw/sysctl.conf
```

#### 20.4.2. Update `before.rules`
sudo vi /etc/ufw/before.rules
```
*filter
...
...
COMMIT

//Add this to the bottom.
*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080
-A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
COMMIT
```

#### 20.4.3. Update ufw rules
```
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo systemctl restart ufw
```

#### 20.4.4. Reboot server
Sometimes it takes a reboot for things to work.

## Note(s)
```bash

```
