#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Einlesen der Variablen

if [ -f /etc/config/cfg/gateway ]; then
   echo [gateway       :  analyse configuration file ]
   lines=$(cat /etc/config/cfg/gateway | wc -l)
   echo [gateway       :  we found $lines entrys ]
   index_wireguard="2"
   line_number="1"
   INFILE=/etc/config/cfg/gateway
   while read -r LINE
         do

         user=$(printf '%s\n' "$LINE"| awk '{print $1}')
         country=$(printf '%s\n' "$LINE"| awk '{print $2}')
         internal_network=$(printf '%s\n' "$LINE"| awk '{print $3}')
         proxy_port=$(printf '%s\n' "$LINE"| awk '{print $4}')
         redsocks_port=$(printf '%s\n' "$LINE"| awk '{print $5}')
         ssh_user=$(printf '%s\n' "$LINE"| awk '{print $6}')
         dns_server=$(printf '%s\n' "$LINE"| awk '{print $7}')
         searching=$(printf '%s\n' "$LINE"| awk '{print $8}')
         ssh_port="22"
         dns_port="53"
         tor_port="9050"
         http_port="80"
         https_port="443"
         smtp_port="25"
         pop3_port="110"
         smtp_new_01_port="465"
         smtp_new_02_port="587"
         imap_01_port="143"
         imap_02_port="993"
         pop3s_port="995"
         dns_tls_port="853"
         sftp_01_port="989"
         sftp_02_port="990"
         service_01_port="5222"
         service_02_port="5223"
         service_03_port="5228"
         service_04_port="5229"
         service_05_port="5230"
         service_06_port="5938"
         service_07_port="3389"

         # Port 22 SSH weiterleiten

         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp --dport $ssh_port -j RETURN

         # tor weiterleiten

         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp --dport $tor_port -j RETURN

         # DNS weiterleiten

         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p udp \
         --dport $dns_port  -d $dns_server -j RETURN
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $dns_port  -d $dns_server -j RETURN

         # Port 80 und 443 umleiten

         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $http_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p udp \
         --dport $http_port -j DNAT --to-destination $redsocks_port

         /usr/sbin/iptables  -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $https_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables  -t nat -A PREROUTING -m iprange --src-range $internal_network -p udp \
         --dport $https_port -j DNAT --to-destination $redsocks_port

         # Port 25 und 110 umleiten (alte Clients)

         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $smtp_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network  -p tcp \
         --dport $pop3_port -j DNAT --to-destination $redsocks_port

         # smtp für neuere Clients umleiten

         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $smtp_new_01_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network  -p tcp \
         --dport $smtp_new_02_port -j DNAT --to-destination $redsocks_port

         # IMAP umleiten

         /usr/sbin/iptables    -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $imap_01_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables    -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $imap_02_port -j DNAT --to-destination $redsocks_port

         # POP3S umleiten

         /usr/sbin/iptables  -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $pop3s_port -j DNAT --to-destination $redsocks_port

         # DNS over TLS umleiten

         /usr/sbin/iptables    -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $dns_tls_port -j DNAT --to-destination $redsocks_port

         # FTPS umleiten

         /usr/sbin/iptables    -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $sftp_01_port -j DNAT --to-destination $redsocks_port

         /usr/sbin/iptables    -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $sftp_02_port -j DNAT --to-destination $redsocks_port

         # Spezielle Ports für Google Play,Google Chrome und WhatsApp

         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $service_01_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $service_02_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $service_03_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $service_04_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $service_05_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $service_06_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         --dport $service_07_port -j DNAT --to-destination $redsocks_port
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p udp \
         --dport $service_07_port -j DNAT --to-destination $redsocks_port

         # Und ab hier wollen wie einfach mal schauen, was schlussendlich noch probiert durch
         # unsere sehr eng definierte Firewall zu schlüpfen. Dienste können nun einfach weiter
         # hinzugefügt werden, sollte dies in Zukunft nötig werden.

         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p udp \
         -j LOG --log-level warning --log-prefix "Client UDP redirect blocked"
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p udp \
         -j RETURN
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         -j LOG --log-level warning --log-prefix "Client TCP redirect blocked"
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $internal_network -p tcp \
         -j RETURN

         # Starten des WG Interfaces

         systemctl start wg-quick@wg$index_wireguard

         line_number=$((line_number+1))
         index_wireguard=$((index_wireguard+1))
   done < "$INFILE"

   echo [gateway       :  we are done here ]

   gw_user=$(cat /etc/config/cfg/gateway_user)
   cd /home/$gw_user
   su $gw_user ./ssh_connections.sh > /dev/null 2>&1 &

   echo [gateway       :  external ssh-connections started ]

   redsocks -c /etc/redsocks.conf

   echo [gateway       :  redsocks converter started ]

   systemctl stop stubby
   systemctl start stubby

   exit 0
else
   exit 0
fi


