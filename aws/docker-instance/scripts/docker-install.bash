#!/bin/bash -e

ELK_ADDRESS="${elk_address}"
ELK_PASSWORD="${elk_password}"
ELK_DOCKER_INDEX="${elk_docker_index}"

exec > >(logger -t user-data -s 2>/dev/console) 2>&1

function setup_rsyslog() {
  yum install rsyslog-elasticsearch -y
  cat <<-EOF > /etc/rsyslog.d/elk.conf
module(load="omelasticsearch")
timezone(id="ITC" offset="+07:00")
template(name="IPATemplate"
         type="list"
         option.json="on") {
           constant(value="{")
             constant(value="\"timestamp\":\"")      property(name="timereported" dateFormat="rfc3339")
             constant(value="\",\"message\":\"")     property(name="msg")
             constant(value="\",\"host\":\"")        property(name="hostname")
             constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
             constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
             constant(value="\",\"syslogtag\":\"")   property(name="syslogtag")
           constant(value="\"}")
         }
action(type="omelasticsearch"
       server="$ELK_ADDRESS"
       serverport="9200"
       template="IPATemplate"
       searchIndex="$ELK_DOCKER_INDEX"
       bulkmode="on"
       maxbytes="100m"
       queue.type="linkedlist"
       queue.size="5000"
       queue.dequeuebatchsize="300"
       action.resumeretrycount="-1"
       uid="elastic"
       pwd="$ELK_PASSWORD")
EOF

  systemctl restart rsyslog
  curl -u elastic:$ELK_PASSWORD -f -X POST -H 'Content-Type: application/json' -H 'kbn-xsrf: anything' http://$ELK_ADDRESS:5601/api/saved_objects/index-pattern '-d{"attributes":{"title":"'"$ELK_DOCKER_INDEX"'","timeFieldName":"timestamp"}}'
}

function setup_docker() {
  ip li set mtu 1200 dev eth0
  yum update -y
  yum install -y git yum-utils device-mapper-persistent-data lvm2 nginx epel-release
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  yum install docker-ce docker-ce-cli containerd.io -y
  systemctl start docker
  systemctl enable docker
  usermod -aG docker centos
  newgrp docker
  curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  echo "Docker was installed completely!!!"
}

setup_rsyslog
setup_docker