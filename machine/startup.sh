#!/bin/bash
set -euo pipefail

if [ -f /var/local/completed_startup ]; then
  exit 0
fi

apt-get update
apt-get install wireguard -y

echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.conf
sysctl -p

mkdir -p /etc/wireguard
WG_PRIVATE_KEY=$(wg genkey | tee /etc/wireguard/privatekey)

# Generate /etc/wireguard/wg0.conf
WG0_CONF_FILE=/etc/wireguard/wg0.conf
cat << EOF > $WG0_CONF_FILE
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PreDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
PrivateKey = $WG_PRIVATE_KEY

PostUp = tc qdisc add dev wg0 parent root handle 1: hfsc default 1
PostUp = tc class add dev wg0 parent 1: classid 1:1 hfsc sc rate 200mbit ul rate 200mbit

EOF

systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

touch /var/local/completed_startup
