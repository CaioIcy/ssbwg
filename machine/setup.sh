#!/bin/bash
set -euo pipefail

WG0_CONF_FILE=/etc/wireguard/wg0.conf
WG_PUBLIC_KEY=$(cat /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey)
EXTERNAL_IP=$(curl ifconfig.me/ip)

# Update WG0_CONF_FILE with tc filters for each peer.
for i in {2..254}
do
  # Use tc to limit bandwith for each peer
  cat << EOF >> $WG0_CONF_FILE
PostUp = tc class add dev wg0 parent 1:1 classid 1:$i hfsc ls rate 800kbit ul rate 800kbit
PostUp = tc filter add dev wg0 parent 1: protocol ip prio 1 u32 match ip dst 10.8.0.$i classid 1:$i
EOF
done

# Create peers.conf file.
PEER_CONFIG_FILE="/etc/wireguard/peers.conf"
touch $PEER_CONFIG_FILE
for i in {2..254}
do
  # Generate private and public keys for the peer
  PEER_PRIVATE_KEY=$(wg genkey)
  PEER_PUBLIC_KEY=$(echo $PEER_PRIVATE_KEY | wg pubkey)

  # Add peer to wg0.conf
  cat << EOF >> $WG0_CONF_FILE

[Peer]
# Name = peer-$i
PublicKey = $PEER_PUBLIC_KEY
AllowedIPs = 10.8.0.$i/24
EOF

  # Create a configuration file for the peer
  cat << EOF >> $PEER_CONFIG_FILE
##################################
[Interface]
# Name = peer-$i
Address = 10.8.0.$i/24
PrivateKey = $PEER_PRIVATE_KEY

[Peer]
AllowedApps = Slippi Dolphin
AllowedIPs = 0.0.0.0/0
Endpoint = $EXTERNAL_IP:51820
PersistentKeepalive = 25
PublicKey = $WG_PUBLIC_KEY

EOF
done

systemctl restart wg-quick@wg0
