#!/bin/bash

systemctl restart sshd > /dev/null 2>&1
systemctl start redsocks > /dev/null 2>&1

killall -u $1 > /dev/null 2>&1

echo $3 > /home/$1/p1
echo $4 > /home/$1/p2
echo $5 > /home/$1/p3
echo $6 > /home/$1/p4
echo $7 > /home/$1/p5
echo $8 > /home/$1/p6
echo $9 > /home/$1/p7
echo ${10} > /home/$1/p8
echo ${11} > /home/$1/p9
echo ${12} > /home/$1/p10
echo ${13} > /home/$1/p11

chown $1:$1 /home/$1/p1
chown $1:$1 /home/$1/p2
chown $1:$1 /home/$1/p3
chown $1:$1 /home/$1/p4
chown $1:$1 /home/$1/p5
chown $1:$1 /home/$1/p6
chown $1:$1 /home/$1/p7
chown $1:$1 /home/$1/p8
chown $1:$1 /home/$1/p9
chown $1:$1 /home/$1/p10
chown $1:$1 /home/$1/p11

su $1 ./ssh1.sh &

sleep 2

while true
do
  sleep 10

  # Checking the socks5 proxy connection

  curl --connect-timeout 6 --max-time 8 -i --socks5 172.29.255.1:8080 https://www.google.de > /dev/null 2>&1
  rc1=$?
  if [ "$rc1" == "0" ] ; then
      echo "ssh-socks5 server on 172.29.255.1 Port 8080 is alive "$(date)
      sleep 15
  else
      echo "rc from curl socks5 is :" $rc1

      if [ "$rc1" == "7" ] ; then
         echo "ssh-connection killed and restartet rc:="$rc1 $(date)

         killall -u $1  > /dev/null 2>&1
         sleep 1
         su $1 ./ssh1.sh &
         sleep 30
      fi

      if [ "$rc1" == "27" ] ; then
         echo "ssh-connection killed and restartet rc:="$rc1 $(date)
         killall -u $1  > /dev/null 2>&1
         sleep 1
         su $1 ./ssh1.sh &
         sleep 30
      fi

      if [ "$rc1" == "97" ] ; then
         echo "ssh-connection killed and restartet rc:="$rc1 $(date)
         killall -u $1  > /dev/null 2>&1
         sleep 1
         su $1 ./ssh1.sh &
         sleep 30
      fi
  fi

  # Checking redirection to proxy

  if [ "$rc1" == "0" ] ; then

     curl --connect-timeout 15 --max-time 20 -i https://www.heise.de > /dev/null 2>&1
     rc2=$?
     if [ "$rc2" == "0" ] ; then
        echo "redsocks redirect on 172.29.255.1 Port 1081 is alive "$(date)
        sleep 15
     else
       if [ "$rc2" == "28" ] ; then
          echo "redsocks redirect action restarts rc:="$rc2 $(date)
          systemctl stop redsocks
          systemctl start redsocks
       else
          echo "redsocks redirect action none rc:="$rc2 $(date)
       fi

     fi
  fi
done












