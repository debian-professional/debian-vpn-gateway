#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ -f /etc/config/cfg/nvpn ]; then
   while true
   do
     sleep 30
     status=$(nordvpn status | grep Connected)
     rc0=$?
     if [ "$rc0" == "0" ] ; then
        echo VPN is Connected .....
     else
        echo VPN is not Connected anymore ...
        cd /etc/config
        ./vpn.sh
     fi
   done
fi


