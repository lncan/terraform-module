#!/bin/bash -e

IPA_HOSTNAME="${ipa_hostname}"
IPA_IP="${ipa_ip}"
IPA_ADMIN_PASSWORD="${ipa_admin_password}"
IPA_DM_PASSWORD="${ipa_dm_password}"
IPA_REALM="${ipa_realm}"
ELK_ADDRESS="${elk_address}"
ELK_PASSWORD="${elk_password}"
ELK_IPA_INDEX="${elk_ipa_index}"

hostnamectl set-hostname $IPA_HOSTNAME

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
       searchIndex="$ELK_IPA_INDEX"
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
  curl -u elastic:$ELK_PASSWORD -f -X POST -H 'Content-Type: application/json' -H 'kbn-xsrf: anything' http://$ELK_ADDRESS:5601/api/saved_objects/index-pattern '-d{"attributes":{"title":"'"$ELK_IPA_INDEX"'","timeFieldName":"timestamp"}}'
}

function setup_ipa() {
  ip li set mtu 1200 dev eth0
  setenforce 0
  yum install ipa-server ipa-server-dns bind-dyndb-ldap -y
  echo "$IPA_IP $IPA_HOSTNAME" | tee -a /etc/hosts
  ipa-server-install --unattended --no-host-dns --setup-dns --forwarder=8.8.8.8 \
  --allow-zone-overlap -a $IPA_ADMIN_PASSWORD --hostname=$IPA_HOSTNAME \
  -p $IPA_DM_PASSWORD -r $IPA_REALM
  echo "Setup IPA completed!"
}

setup_rsyslog
setup_ipa