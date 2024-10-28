#!/bin/bash

su $1 ./start-tor.sh > /dev/null 2>&1 &

sleep 15

while true
 do
   rm /etc/config/scripts/tornode3ip.log > /dev/null 2>&1
   curl --silent --proxy socks5h://172.29.255.1:9050 'https://wtfismyip.com/yaml' | grep YourFucking > /etc/config/scripts/tornode3ip.log 2>&1
   sleep 600
 done


