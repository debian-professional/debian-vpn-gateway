#!/bin/bash

if [ $# -eq 0 ]; then
    echo "no arguments"
    arguments="no"
else
    echo "have arguments"
    arguments="yes"
fi

if [ -f /etc/config/cfg/gateway ]; then
   host1_command=$(cat /etc/config/cfg/gw-host1)
   host2_command=$(cat /etc/config/cfg/gw-host2)
   host3_command=$(cat /etc/config/cfg/gw-host3)
   host4_command=$(cat /etc/config/cfg/gw-host1)
else
   host1_command=""
   host2_command=""
   host3_command=""
   host4_command=""
fi

while true
do

rm /tmp/links > /dev/null 2>&1

echo random list generating ......

i=0
while [ $i -ne 20 ]
do
        i=$(($i+1))
        if [ -f /etc/config/cfg/gateway ]; then
           curl --silent --proxy socks5h://172.29.255.1:9050  https://www.boredbutton.com/random | \
           grep iframe | grep src |  tr '"' ' ' | awk '{print $3}' >> /tmp/links
        else
           curl --silent --proxy socks5h://172.29.255.1:9050 https://www.boredbutton.com/random | \
           grep iframe | grep src |  tr '"' ' ' | awk '{print $3}' >> /tmp/links
        fi
        echo $i
done
echo random list is now generated ......

line_number="1"
INFILE=/tmp/links
while read -r LINE
      do
      url=$(printf '%s\n' "$LINE"| awk '{print $1}')
      rvalue=$(shuf -i 1-14 -n 1 -r)

      if [ "$rvalue" -eq 0 ]; then
         if [ $arguments = "yes" ]; then
            echo 0 : $url
            curl --silent --proxy socks5h://172.29.255.1:9050 $url
            proxychains $(echo $host1_command)
         else
            echo 0 : $url        > /dev/null 2>&1
            curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
         fi
      fi

      if [ "$rvalue" -eq 1 ]; then
         if [ $arguments = "yes" ]; then
            echo 1 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host2_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 1 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host2_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi

      if [ "$rvalue" -eq 2 ]; then
         if [ $arguments = "yes" ]; then
            echo 2 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host3_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 2 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host3_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi


      if [ "$rvalue" -eq 3 ]; then
         if [ $arguments = "yes" ]; then
            echo 3 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host4_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 3 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host4_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi


      if [ "$rvalue" -eq 4 ]; then
         if [ $arguments = "yes" ]; then
            echo 4 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host1_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 4 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host1_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi


      if [ "$rvalue" -eq 5 ]; then
         if [ $arguments = "yes" ]; then
            echo 5 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host2_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 5 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host2_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi


      if [ "$rvalue" -eq 6 ]; then
         if [ $arguments = "yes" ]; then
            echo 6 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host3_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 6 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host3_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi

      if [ "$rvalue" -eq 7 ]; then
         if [ $arguments = "yes" ]; then
            echo 7 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host4_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 7 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host4_command)
             else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi

      if [ "$rvalue" -eq 8 ]; then
         if [ $arguments = "yes" ]; then
            echo 8 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host1_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 8 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host1_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi


      if [ "$rvalue" -eq 9 ]; then
         if [ $arguments = "yes" ]; then
            echo 9 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host2_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 9 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host2_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi


      if [ "$rvalue" -eq 10 ]; then
         if [ $arguments = "yes" ]; then
            echo 10 : $url
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
               proxychains $(echo $host3_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url
            fi
         else
            echo 10 : $url > /dev/null 2>&1
            if [ -f /etc/config/cfg/gateway ]; then
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
               proxychains $(echo $host3_command)
            else
               curl --silent --proxy socks5h://172.29.255.1:9050 $url > /dev/null 2>&1
            fi
         fi
      fi

      line_number=$((line_number+1))


done < "$INFILE"
echo random list all destinations visited ....

done


