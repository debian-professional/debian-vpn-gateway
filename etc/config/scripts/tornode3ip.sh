#!/bin/bash

sleep 15
 
while true
 do
   rm /etc/config/scripts/tornode3ip.log > /dev/null 2>&1
   curl --proxy socks5h://172.29.255.1:9050 'https://wtfismyip.com/yaml' > /etc/config/scripts/tornode3ip.log 2>&1
   sleep 600
 done

