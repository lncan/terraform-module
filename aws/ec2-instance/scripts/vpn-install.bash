#!/bin/bash

AD_DOMAIN_NAME="${ad_domain_name}"
AD_IP_ADDRESS="${ad_ip_address}"
AD_PRIMARY_DOMAIN="${ad_primary_domain}"
AD_ADMIN_USERNAME="${ad_admin_username}"
AD_ADMIN_PASSWORD="${ad_admin_password}"
YOUR_IPSEC_PSK="${client_server_psk}"
OFFICE_PUBLIC_IP="${office_public_ip}"
OFFICE_SUBNET="${office_network}"
XAUTH_NET="${vpc_network}"
XAUTH_POOL="${vpn_client_ip_pool}"
SITE_TO_SITE_PSK="${site_to_site_psk}"
DNS_SRVS1="${vpn_dns_server}"
VPN_HOSTNAME="${vpn_hostname}"

setenforce 0
ip li set mtu 1200 dev eth0 
hostnamectl set-hostname $VPN_HOSTNAME

exec > >(logger -t user-data -s 2>/dev/console) 2>&1

function setup_webserver() {
  yum update -y
  yum install -y epel-release
  yum install nginx -y
  systemctl enable --now nginx
  setsebool -P httpd_can_network_connect 1
}

function setup_vpn() {
  yum install freeipa-client -y
  echo "$AD_IP_ADDRESS $AD_DOMAIN_NAME" | tee -a /etc/hosts
  ipa-client-install --hostname=`hostname -f` --mkhomedir --server=$AD_DOMAIN_NAME --domain=$AD_PRIMARY_DOMAIN  --force-join -p $AD_ADMIN_USERNAME -w $AD_ADMIN_PASSWORD --unattended

  DNS_SRVS2=$(grep -v '#' "/etc/resolv.conf" | grep nameserver | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

  export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  SYS_DT=$(date +%F-%T)

  exiterr()  { echo "Error: $1" >&2; exit 1; }
  exiterr2() { exiterr "'yum install' failed."; }
  conf_bk() { /bin/cp -f "$1" "$1.old-$SYS_DT" 2>/dev/null; }
  bigecho() { echo; echo "## $1"; echo; }

  check_ip() {
    IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
    printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
  }

  vpnsetup() {

  if ! grep -qs -e "release 6" -e "release 7" -e "release 8" /etc/redhat-release; then
    echo "Error: This script only supports CentOS/RHEL 6, 7 and 8." >&2
    echo "For Ubuntu/Debian, use https://git.io/vpnsetup" >&2
    exit 1
  fi

  if [ -f /proc/user_beancounters ]; then
    exiterr "OpenVZ VPS is not supported. Try OpenVPN: github.com/Nyr/openvpn-install"
  fi

  if [ "$(id -u)" != 0 ]; then
    exiterr "Script must be run as root. Try 'sudo sh $0'"
  fi

  def_iface=$(route 2>/dev/null | grep -m 1 '^default' | grep -o '[^ ]*$')
  [ -z "$def_iface" ] && def_iface=$(ip -4 route list 0/0 2>/dev/null | grep -m 1 -Po '(?<=dev )(\S+)')
  def_state=$(cat "/sys/class/net/$def_iface/operstate" 2>/dev/null)
  if [ -n "$def_state" ] && [ "$def_state" != "down" ]; then
    case "$def_iface" in
      wl*)
        exiterr "Wireless interface '$def_iface' detected. DO NOT run this script on your PC or Mac!"
        ;;
    esac
    NET_IFACE="$def_iface"
  else
    eth0_state=$(cat "/sys/class/net/eth0/operstate" 2>/dev/null)
    if [ -z "$eth0_state" ] || [ "$eth0_state" = "down" ]; then
      exiterr "Could not detect the default network interface."
    fi
    NET_IFACE=eth0
  fi

  [ -n "$YOUR_IPSEC_PSK" ] && VPN_IPSEC_PSK="$YOUR_IPSEC_PSK"

  if [ -z "$VPN_IPSEC_PSK" ]; then
    bigecho "VPN credentials not set by user. Generating random PSK and password..."
    VPN_IPSEC_PSK=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 20)
  fi

  if [ -z "$VPN_IPSEC_PSK" ]; then
    exiterr "All VPN credentials must be specified. Edit the script and re-enter them."
  fi

  if printf '%s' "$VPN_IPSEC_PSK" | LC_ALL=C grep -q '[^ -~]\+'; then
    exiterr "VPN credentials must not contain non-ASCII characters."
  fi

  case "$VPN_IPSEC_PSK" in
    *[\\\"\']*)
      exiterr "VPN credentials must not contain these special characters: \\ \" '"
      ;;
  esac

  bigecho "VPN setup in progress... Please be patient."

  # Create and change to working dir
  mkdir -p /opt/src
  cd /opt/src || exit 1

  bigecho "Installing packages required for setup..."

  yum -y install wget bind-utils openssl tar \
    iptables iproute gawk grep sed net-tools || exiterr2

  bigecho "Trying to auto discover IP of this server..."

  cat <<'EOF'
In case the script hangs here for more than a few minutes,
press Ctrl-C to abort. Then edit it and manually enter IP.
EOF

  # In case auto IP discovery fails, enter server's public IP here.
  PUBLIC_IP=$VPN_PUBLIC_IP

  [ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)

  check_ip "$PUBLIC_IP" || PUBLIC_IP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
  check_ip "$PUBLIC_IP" || exiterr "Cannot detect this server's public IP. Edit the script and manually enter it."

  bigecho "Adding the EPEL repository..."

  # yum -y install epel-release || yum -y install "$epel_url" || exiterr2

  yum -y install epel-release

  bigecho "Installing packages required for the VPN..."

  REPO1='--enablerepo=epel'
  REPO2='--enablerepo=*server-optional*'
  REPO3='--enablerepo=*releases-optional*'
  REPO4='--enablerepo=PowerTools'

  yum -y install nss-devel nspr-devel pkgconfig pam-devel \
    libcap-ng-devel libselinux-devel curl-devel nss-tools \
    flex bison gcc make ppp || exiterr2

  yum "$REPO1" -y install xl2tpd || exiterr2

  if grep -qs "release 6" /etc/redhat-release; then
    yum -y remove libevent-devel
    yum "$REPO2" "$REPO3" -y install libevent2-devel fipscheck-devel || exiterr2
  elif grep -qs "release 7" /etc/redhat-release; then
    yum -y install systemd-devel iptables-services || exiterr2
    yum "$REPO2" "$REPO3" -y install libevent-devel fipscheck-devel || exiterr2
  else
    if [ -f /usr/sbin/subscription-manager ]; then
      subscription-manager repos --enable "codeready-builder-for-rhel-8-*-rpms"
      yum -y install systemd-devel iptables-services libevent-devel fipscheck-devel || exiterr2
    else
      yum "$REPO4" -y install systemd-devel iptables-services libevent-devel fipscheck-devel || exiterr2
    fi
  fi

  sudo ln -s /usr/local/sbin/ipsec /usr/sbin/ipsec

  bigecho "Installing Fail2Ban to protect SSH..."

  yum "$REPO1" -y install fail2ban || exiterr2

  bigecho "Compiling and installing Libreswan..."

  SWAN_VER=3.29
  swan_file="libreswan-$SWAN_VER.tar.gz"
  swan_url1="https://github.com/libreswan/libreswan/archive/v$SWAN_VER.tar.gz"
  swan_url2="https://download.libreswan.org/$swan_file"
  if ! { wget -t 3 -T 30 -nv -O "$swan_file" "$swan_url1" || wget -t 3 -T 30 -nv -O "$swan_file" "$swan_url2"; }; then
    exit 1
  fi
  /bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
  tar xzf "$swan_file" && /bin/rm -f "$swan_file"
  cd "libreswan-$SWAN_VER" || exit 1
  cat > Makefile.inc.local <<'EOF'
WERROR_CFLAGS =
USE_DNSSEC = false
USE_DH31 = false
USE_NSS_AVA_COPY = true
USE_NSS_IPSEC_PROFILE = false
USE_GLIBC_KERN_FLIP_HEADERS = true
EOF
  NPROCS=$(grep -c ^processor /proc/cpuinfo)
  [ -z "$NPROCS" ] && NPROCS=1
  make "-j$((NPROCS+1))" -s base && make -s install-base

  cd /opt/src || exit 1
  /bin/rm -rf "/opt/src/libreswan-$SWAN_VER"
  if ! /usr/local/sbin/ipsec --version 2>/dev/null | grep -qF "$SWAN_VER"; then
    exiterr "Libreswan $SWAN_VER failed to build."
  fi

  bigecho "Creating VPN configuration..."

  # Create IPsec config
  conf_bk "/etc/ipsec.conf"
  cat > /etc/ipsec.conf <<EOF
version 2.0
config setup
  virtual-private=%v4:$OFFICE_SUBNET,%v4:$XAUTH_NET
  protostack=netkey
  interfaces=%defaultroute
  uniqueids=no

conn remote2local
  aggressive=no
  authby=secret
  left=%defaultroute
  leftid=$PUBLIC_IP
  leftsubnet=$XAUTH_NET
  right=$OFFICE_PUBLIC_IP
  rightsubnet=$OFFICE_SUBNET
  ike=aes256-sha2_256-modp1024
  esp=aes256-sha2_256
  keyingtries=0
  dpdaction=restart
  dpddelay=30
  dpdtimeout=120
  ikelifetime=1h
  salifetime=8h
  auto=start

conn shared
  left=%defaultroute
  leftid=$PUBLIC_IP
  right=%any
  encapsulation=yes
  authby=secret
  pfs=no
  rekey=no
  keyingtries=5
  dpddelay=30
  dpdtimeout=120
  dpdaction=clear
  ikev2=never
  ike=aes256-sha2,aes128-sha2,aes256-sha1,aes128-sha1,aes256-sha2;modp1024,aes128-sha1;modp1024
  phase2alg=aes_gcm-null,aes128-sha1,aes256-sha1,aes256-sha2_512,aes128-sha2,aes256-sha2
  sha2-truncbug=no

conn xauth-psk
  auto=add
  leftsubnet=0.0.0.0/0
  rightaddresspool=$XAUTH_POOL
  modecfgdns=$DNS_SRVS1,$DNS_SRVS2
  leftxauthserver=yes
  rightxauthclient=yes
  leftmodecfgserver=yes
  rightmodecfgclient=yes
  modecfgpull=yes
  xauthby=pam
  ike-frag=yes
  cisco-unity=yes
  also=shared
EOF

  # Specify IPsec PSK
  conf_bk "/etc/ipsec.secrets"
  cat > /etc/ipsec.secrets <<EOF
%any  %any  : PSK "$VPN_IPSEC_PSK"
$PUBLIC_IP $OFFICE_PUBLIC_IP : PSK "$SITE_TO_SITE_PSK"
EOF

  bigecho "Updating sysctl settings..."

  if ! grep -qs "hwdsl2 VPN script" /etc/sysctl.conf; then
    conf_bk "/etc/sysctl.conf"
    if [ "$(getconf LONG_BIT)" = "64" ]; then
      SHM_MAX=68719476736
      SHM_ALL=4294967296
    else
      SHM_MAX=4294967295
      SHM_ALL=268435456
    fi
  cat >> /etc/sysctl.conf <<EOF
# Added by hwdsl2 VPN script
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = $SHM_MAX
kernel.shmall = $SHM_ALL
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.$NET_IFACE.send_redirects = 0
net.ipv4.conf.$NET_IFACE.rp_filter = 0
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
EOF
  fi

  bigecho "Updating IPTables rules..."

  # Check if rules need updating
  ipt_flag=0
  IPT_FILE="/etc/sysconfig/iptables"
  if ! grep -qs "hwdsl2 VPN script" "$IPT_FILE" \
    || ! iptables -t nat -C POSTROUTING -s "$XAUTH_NET" -o "$NET_IFACE" -m policy --dir out --pol none -j MASQUERADE 2>/dev/null; then
    ipt_flag=1
  fi

  # Add IPTables rules for VPN
  if [ "$ipt_flag" = "1" ]; then
    service fail2ban stop >/dev/null 2>&1
    iptables-save > "$IPT_FILE.old-$SYS_DT" 
    iptables -I INPUT 1 -p udp --dport 1701 -m policy --dir in --pol none -j DROP
    iptables -I INPUT 2 -m conntrack --ctstate INVALID -j DROP
    iptables -I INPUT 3 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -I INPUT 4 -p udp -m multiport --dports 500,4500 -j ACCEPT
    iptables -I INPUT 5 -p udp --dport 1701 -m policy --dir in --pol ipsec -j ACCEPT
    iptables -I INPUT 6 -p udp --dport 1701 -j DROP
    iptables -I FORWARD 1 -m conntrack --ctstate INVALID -j DROP
    iptables -I FORWARD 2 -i "$NET_IFACE" -o ppp+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -I FORWARD 3 -i ppp+ -o "$NET_IFACE" -j ACCEPT
    iptables -I FORWARD 4 -i "$NET_IFACE" -d "$XAUTH_NET" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    iptables -I FORWARD 5 -s "$XAUTH_NET" -o "$NET_IFACE" -j ACCEPT 
    # Uncomment if you wish to disallow traffic between VPN clients themselves
    # iptables -I FORWARD 3 -s "$XAUTH_NET" -d "$XAUTH_NET" -j DROP
    iptables -t nat -I POSTROUTING -s "$XAUTH_NET" -o "$NET_IFACE" -m policy --dir out --pol none -j MASQUERADE
    iptables -I FORWARD -j ACCEPT
    echo "# Modified by hwdsl2 VPN script" > "$IPT_FILE"
    iptables-save >> "$IPT_FILE"
  fi

  bigecho "Creating basic Fail2Ban rules..."

  if [ ! -f /etc/fail2ban/jail.local ] ; then
  cat > /etc/fail2ban/jail.local <<'EOF'
[ssh-iptables]
enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/secure
EOF
  fi

  bigecho "Enabling services on boot..."

  if grep -qs "release 6" /etc/redhat-release; then
    chkconfig iptables on
    chkconfig fail2ban on
  else
    systemctl --now mask firewalld 2>/dev/null
    systemctl enable iptables fail2ban 2>/dev/null
  fi

  if ! grep -qs "hwdsl2 VPN script" /etc/rc.local; then
    if [ -f /etc/rc.local ]; then
      conf_bk "/etc/rc.local"
    else
      echo '#!/bin/sh' > /etc/rc.local
    fi
  cat >> /etc/rc.local <<'EOF'
# Added by hwdsl2 VPN script
(sleep 15
service ipsec restart
ipsec auto --rereadsecrets
ipsec auto --add remote2local
ipsec auto --up remote2local
echo 1 > /proc/sys/net/ipv4/ip_forward)&
EOF
  fi

  bigecho "Starting services..."
  service ipsec start

  # Restore SELinux contexts
  restorecon /etc/ipsec.d/*db 2>/dev/null
  restorecon /usr/local/sbin -Rv 2>/dev/null
  restorecon /usr/local/libexec/ipsec -Rv 2>/dev/null

  # Reload sysctl.conf
  sysctl -e -q -p

  # Update file attributes
  chmod +x /etc/rc.local
  chmod 600 /etc/ipsec.secrets* /etc/ppp/chap-secrets*

  # Apply new IPTables rules
  iptables-restore < "$IPT_FILE"

  #Install stable libreswan version
  yum install libreswan -y

  # Restart services
  mkdir -p /run/pluto
  service fail2ban restart 2>/dev/null
  service ipsec restart 2>/dev/null

  cat <<EOF
  ================================================
  IPsec VPN server is now ready for use!
  Connect to your new VPN server with these details:
  IPsec PSK: $VPN_IPSEC_PSK
  Username: <Your-LDAP-Username>
  Password: <Your-LDAP-Password>
  Write these down. You'll need them to connect!
  ================================================
  Setup VPN completed!
EOF

  }

## Defer setup until we have the complete script
  vpnsetup "$@"

  exit 0
}

setup_webserver
setup_vpn