#!/bin/bash

su $1 ./start-tor.sh > /dev/null 2>&1 &

sleep 15

while true
 do
   rm /etc/config/scripts/tornode3ip.log > /dev/null 2>&1
   curl --silent --proxy socks5h://172.29.255.1:9050 'https://wtfismyip.com/yaml' | grep YourFucking > /etc/config/scripts/tornode3ip.log 2>&1
   rm /tmp/links2 > /dev/null 2>&1
   i=0
   while [ $i -ne 20 ]
   do
        i=$(($i+1))
        curl --silent --proxy socks5h://172.29.255.1:9050  https://www.boredbutton.com/random | \
        grep iframe | grep src |  tr '"' ' ' | awk '{print $3}' >> /tmp/links2
    done
    line_number="1"
    INFILE=/tmp/links2
    while read -r LINE
    do
      url=$(printf '%s\n' "$LINE"| awk '{print $1}')
      echo ............
      echo $line_number
      echo $url
      echo .............
      curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
      line_number=$((line_number+1))
    done < "$INFILE"
 done


