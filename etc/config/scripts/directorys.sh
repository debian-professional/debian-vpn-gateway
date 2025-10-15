#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ -d /etc/config ]; then
   cd /etc/config
else
   mkdir /etc/config
fi

# directorys

ln -s /home/source/debian-vpn-gateway/etc/config/backup backup
ln -s /home/source/debian-vpn-gateway/etc/config/deb deb
ln -s /home/source/debian-vpn-gateway/etc/config/doc doc
ln -s /home/source/debian-vpn-gateway/etc/config/scripts scripts

# scripts

ln -s /home/source/debian-vpn-gateway/etc/config/firewall.sh firewall.sh
ln -s /home/source/debian-vpn-gateway/etc/config/get-nordvpn.sh get-nordvpn.sh
ln -s /home/source/debian-vpn-gateway/etc/config/get-pi-hole.sh get-pihole.sh
ln -s /home/source/debian-vpn-gateway/etc/config/off.sh off.sh

cd /etc

ln -s /home/source/debian-vpn-gateway/etc/rc.local rc.local
