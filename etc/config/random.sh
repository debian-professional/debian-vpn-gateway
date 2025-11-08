#!/bin/bash


rm /tmp/links > /dev/null 2>&1

echo random list generating ......

i=0
while [ $i -ne 20 ]
do
        i=$(($i+1))
        curl --silent --proxy socks5h://172.29.255.1:9050  https://www.boredbutton.com/random | \
        grep iframe | grep src |  tr '"' ' ' | awk '{print $3}' >> /tmp/links
done
echo random list generated ......

line_number="1"
INFILE=/tmp/links
while read -r LINE
      do
      url=$(printf '%s\n' "$LINE"| awk '{print $1}')
      rvalue=$(shuf -i 1-10 -n 1 -r)

      if [ "$rvalue" -eq 0 ]; then
         echo 0 : $url
         curl --silent $url
      fi

      if [ "$rvalue" -eq 1 ]; then
         echo 1 : $url
         curl --silent --proxy socks5h://172.29.255.1:1080 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 2 ]; then
         echo 2 : $url
         curl --silent --proxy socks5h://172.29.255.1:1081 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 3 ]; then
         echo 3 : $url
         curl --silent --proxy socks5h://172.29.255.1:1082 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 4 ]; then
         echo 4 : $url
         curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 5 ]; then
         echo 5 : $url
         curl --silent --proxy socks5h://172.29.255.1:1082 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 6 ]; then
         echo 6 : $url
         curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 7 ]; then
         echo 7 : $url
         curl --silent --proxy socks5h://172.29.255.1:1082 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 8 ]; then
         echo 8 : $url
         curl --silent --proxy socks5h://172.29.255.1:1081 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 9 ]; then
         echo 9 : $url
         curl --silent --proxy socks5h://172.29.255.1:1080 $url > /dev/null 2>&1
      fi

      if [ "$rvalue" -eq 10 ]; then
         echo 10 : $url
         curl --silent $url > /dev/null 2>&1
      fi

      line_number=$((line_number+1))
      sleep $rvalue

done < "$INFILE"
echo random list all destinations visited ....

