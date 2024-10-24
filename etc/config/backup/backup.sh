#!/bin/bash

# delete old files

cd /etc/config/backup/tmp
rm -rf *  > /dev/null 2>&1
cd /etc/config/backup

# user root

find /root/.ssh > backup-files
find /root/.bashrc >> backup-files
find /root/.bash_history >> backup-files

# all other users

find /home | grep .ssh >> backup-files
find /home | grep .bashrc >> backup-files
find /home | grep .bash_history >> backup-files
find /home | grep .bash_logout >> backup-files

tar cvzf tmp/user-files.tar.gz $(cat /etc/config/backup/backup-files) > /dev/null 2>&1

find /etc/config/cfg > backup-files
find /etc/config/cfg01 >> backup-files
find /etc/config/cfg02 >> backup-files
find /etc/config/cfg03 >> backup-files
find /etc/config/backup >> backup-files

tar cvzf tmp/configuration.tar.gz --exclude=/etc/config/backup/tmp $(cat /etc/config/backup/backup-files) > /dev/null 2>&1

# ssh
if [ -e /etc/config/cfg/swtor_ssh_port1 -o -e /etc/config/cfg/swtor_ssh_port2 ] ; then
   tar cvzf tmp/sshd.tar.gz /etc/ssh > /dev/null 2>&1
fi

# Wireguard
if [ -e /etc/config/cfg/wireguard_interface1 -o -e /etc/config/cfg/wireguard_interface2 ] ; then
   tar cvzf tmp/wg.tar.gz /etc/wireguard  > /dev/null 2>&1
fi

# stubby
tar cvzf tmp/stubby.tar.gz /etc/stubby  > /dev/null 2>&1

# Pihole
if [ -f /etc/config/cfg/pihole ]; then
   tar cvzf tmp/pihole.tar.gz /etc/pihole /etc/lighttpd etc/dnsmasq.conf /etc/dnsmasq.d > /dev/null 2>&1
fi

# IPSec
if [ -f /etc/config/cfg/ipsec ]; then
   tar cvzf tmp/ipsec.tar.gz /etc/ipsec.conf /etc/ipsec.secrets  > /dev/null 2>&1
fi

# Virtual Interfaces
if [ -f /etc/config/cfg/virtual_iface ]; then
   tar cvzf tmp/interfaces.tar.gz /etc/network/interfaces > /dev/null 2>&1
fi

# Snowflake-Proxy
if [ -f /etc/config/cfg/swtor_snowflake ]; then
   tar cvzf tmp/snowflake-proxy-service.tar.gz /lib/systemd/snowflake-proxy.service > /dev/null 2>&1
fi

#TOR
if [ -f /etc/config/cfg/swtor_tor ]; then
   tar cvzf tmp/tor.tar.gz /etc/tor > /dev/null 2>&1
fi

# Nice to have inside the backup

tar cvzf tmp/nice_to_have.tar.gz /etc/apt /etc/motd > /dev/null 2>&1
dpkg -l > tmp/installed-software
echo Backup created on $(date '+%Y-%m-%d-%H-%M')  > /etc/config/backup/tmp/backup-was-made.log

# Clean-Up

if [ -f /etc/config/backup/backup-files ]; then
   rm /etc/config/backup/backup-files > /dev/null 2>&1
fi

# And at the end we backup the tmp folder
# with the hostname of the server

backupfile="$(hostname)-$(date '+%Y-%m-%d-%H-%M').tar.gz"
tar cvzf $backupfile /etc/config/backup/tmp > /dev/null 2>&1

cd /etc/config/backup/tmp
rm * > /dev/null 2>&1
cd ..
exit 0









