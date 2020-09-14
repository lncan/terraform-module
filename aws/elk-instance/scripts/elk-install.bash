#!/bin/bash -e

ELK_PASSWORD=${elk_password}

exec > >(logger -t user-data -s 2>/dev/console) 2>&1
ip li set mtu 1200 dev eth0
yum update -y
yum install -y git yum-utils device-mapper-persistent-data lvm2 epel-release
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
usermod -aG docker centos
newgrp docker
curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
git clone https://github.com/deviantony/docker-elk
cd docker-elk && sed -i 's/trial/basic/g' elasticsearch/config/elasticsearch.yml && \
sed -i "s/changeme/$ELK_PASSWORD/g" kibana/config/kibana.yml && \
sed -i "s/changeme/$ELK_PASSWORD/g" logstash/config/logstash.yml && \
sed -i "s/changeme/$ELK_PASSWORD/g" logstash/pipeline/logstash.conf && \
sed -i "s/changeme/$ELK_PASSWORD/g" docker-compose.yml && docker-compose up -d