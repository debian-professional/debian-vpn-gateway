#!/bin/bash
###############################################################################
# Firewall Script : firewall.sh                                               #
# Beschreibung    : Schützen eines privaten VPS                               #
# OS              : Debian 12 Bookworm                                        #
# Virtuell        : Ja unter VMWare                                           #
# Speicher 	  : 1 GB oder 2GB (hängt vom Modell ab)                       #
# Festplatte 	  : 20 oder 40 GB (hängt vom Modell ab)                       #
# Interface       : 1 x GB eth0                                               #
# Volumen         : 2TB oder 5TB (genau ... hängt vom Modell ab)              #
#                                                                             #
#                                                                             #
# Version 0.96a                                                               #
# - IPSec kann nun alle Filter passieren ohne Fehler sofern es benutzt wird   #
# - Virtuelle Interfaces und alle VPN Bereiche werden im Script gesetzt.      #
# - Es kann bei Bedarf eine weitere Wireguard Instanz wg1 gestartet werden.   #
# - Der Start der VPN Vebindung und auch der Start von Wireguard wird hier    #
#   im Skript erledigt.                                                       #
# - Das gesamte Handling liegt nun hier im Skript und nicht mehr in           #
#   verschiedenen Skripten die von Hand augerufen werden müssen.              #
# - Weitere Optimierungen am Skript wie einlesen aller Variablen über das     #
#   cfg Verzeichniss erleichtern das komplette Handling mit Updates           #
# - Support für 3 virtuelle Ethernet Interfaces (eth0) hinzugefügt            #
# - Die Umleitung von normalen http und https Verkehr ist möglich über einen  #
#   externen Socks5 Server.Sehr sinvoll wenn zum Beispiel die BBC behauptet,  #
#   meine verwendete externe IP Adresse  wäre nicht in der UK registriert.    #
# - Der ganze Konfiguration mittels dem WireGuard VPN und auch der IPSec      #
#   Verbindung inkl. der Umleitung von normalen http und https Verkehr auf    #
#   den externen Socks5 Server macht diese Script zu einenm regelrechten      #
#   Bijou der besonderen Art.                                                 #
###############################################################################


# Verwendete Interfaces und Bereiche
# eth0 		Das Tor zu Welt (IP V4).
# eth0:0	Das virtuelle Interface dient als Endpunkt zur Kommunikation mittels IPSec mit
#               dem remote verbundenen Netzwerk.
# eth0:1        Dieses virtuelle Interface wird zum Bereistellen eines nicht öffentlichen SSH-Zugangs
#               verwendet und ebenso als Socks5 Server auf dem Port 8080.Der redsocks-redirector welcher normale
#               Webverbindungen in socks5 konforme Verbindungen übersetzt, arbeitet auf dem lokalten Port
#               1081.Der dazu optionale tor-service läuft auf Port 9050.
# eth0:2        Wird zum jetzigen Zeitpunkt noch nicht verwendet.
# tun0          Dieses Interface wird hauptsächlich für Pihole verwendet.(172.29.255.2)
#               Der DNS Resolver und die Weboberfläche werden mit diesem Interface verbunden
#               damit die Einrichtung ohne Probleme läuft.
# wg0           lauscht auf UDP Port 80 und behinhaltet den Netzwerk-Range 172.255.31.0/24
# wg1           lauscht auf UDP Port 443 und beinhaltet den Netzwerk-Range 172.255.30.0/24

version="0.96a"
figlet firewall $version
swtor_debug="no"
fw_debug="yes"
external_if="ens192"


if [ -f /etc/config/cfg/redirect_wg0 ]; then
   redirect_wg0_to_socks5="yes"
   if [ -f /etc/config/cfg/redirect_port ]; then
      redirect_wg0=$(cat /etc/config/cfg/redirect_port)
   else
      redirect_wg0_to_socks5="no"
      echo Definition des redirect-ports fehlt in der Konfiguration !
      exit 1
   fi

   if [ -f /etc/config/cfg/redirect_user_socks5 ]; then
      redirect_user_socks5=$(cat /etc/config/cfg/redirect_user_socks5)
   else
      redirect_wg0_to_socks5="no"
      echo Definition des redirect-users fehlt in der Konfiguration !
      exit 1
   fi

   if [ -f /etc/config/cfg/redirect_command ]; then
      redirect_command=$(cat /etc/config/cfg/redirect_command)
   else
      redirect_wg0_to_socks5="no"
      echo Definition des redirect-command fehlt in der Konfiguration !
      exit 1
   fi

   if [ -f /usr/bin/curl ]; then
      echo > /dev/null
   else
      redirect_wg0_to_socks5="no"
      echo curl ist nicht installiert !
      exit 1
   fi

   if [ -f /usr/bin/sshpass ]; then
      echo > /dev/null
   else
      redirect_wg0_to_socks5="no"
      echo sshpass ist nicht installiert !
      exit 1
   fi

   if [ -f /usr/sbin/redsocks ]; then
      echo > /dev/null
   else
      redirect_wg0_to_socks5="no"
      echo redsocks ist nicht installiert !
      exit 1
   fi

   if [ -f /usr/bin/killall ]; then
      echo > /dev/null
   else
      redirect_wg0_to_socks5="no"
      echo killall ist nicht installiert !
      exit 1
   fi

else
   redirect_wg0_to_socks5="no"
fi


if [ -f /etc/config/cfg/swtor_snowflake ]; then
   if [ -f /usr/bin/snowflake-proxy ]; then
      using_snowflake="yes"
   else
      echo snowflake-proxy ist nicht installiert !
      exit 1
   fi
else
   using_snowflake="no"
fi

if [ -f /etc/config/cfg/swtor_tor ]; then
   if [ -f /usr/sbin/tor ]; then
      using_tor="yes"
      tor_port=9050
   else
      echo tor ist  nicht installiert !
      using_tor="no"
      exit 1
   fi
else
   using_tor="no"
fi


if [ -f /etc/config/cfg/pihole ]; then

   using_pihole="yes"

   wireguard1_dns=172.29.255.2
   wireguard2_dns=172.29.255.2

   pihole_interface="tun0"
   pihole_ip=172.29.255.2

else

   using_pihole="no"
   wireguard1_dns=172.31.255.1
   wireguard2_dns=172.30.255.1

fi

external_ip=$(cat ./cfg/eth0.ip)

if [ -f /etc/config/cfg/optimize_memory ]; then
   do_log="no"
   do_log_icmp="no"
   swtor_debug="no"
else
   swtor_debug="yes"
   fw_debug="yes"
   do_log="yes"
   do_log_icmp="yes"
fi

only_set_mtu="no"

# only_set_mtu="yes"

if [ $only_set_mtu = "yes" ]; then
   echo firewall is now disabled ....  only_set_mtu is "yes"
   exit 0
fi


#################################################################
# SSH .... Wir kennen es ... wir lieben es.Die Mutter aller     #
# verschlüsselten Verbindungen über ein unsicheres Netzwerk.    #
# Dieses Urgestein der verschlüsselten Verbindungen ist oftmals #
# die letzte Möglichkeit für Leute welche in sehr restriktiven  #
# Ländern leben, die alles daran setzen möglichst viele Arten   #
# der verschlüsselten Verbindungen (TOR,WireGuard,OpenVPN) zu   #
# unterbinden.Ein Hip Hip Hurra dem Erfinder von SSH !!!!       #
#################################################################
# Alle Optionen der SSH Einstellungen werden über das           #
# Vorhanden sein bzw. Fehlen der Dateien im Verzeichniss        #
# /etc/config/cfg bestimmt und bestimmen die zu anzuwendenden   #
# Firwall Regeln                                                #
#                                                               #
# swtor_allow_local_ssh                                         #
# swtor_ssh_port1                                               #
# swtor_ssh_port2                                               #
# swtor_allow_ssh_to_outside                                    #
#################################################################

if [ -f ./cfg/swtor_allow_local_ssh ]; then
   swtor_allow_local_ssh="yes"

   # Der SSH Standard-Port liegt im Normalfall
   # auf TCP Port 22

   if [ -f ./cfg/swtor_ssh_port1 ]; then
      swtor_ssh_port1=$(cat ./cfg/swtor_ssh_port1)
   fi

   # Als zusätzlicher SSH Port 2 bietet sich natürlich
   # der Port TCP 443 für alle verschlüsselten Webseiten
   # natürlich geradezu an.Es gibt allerdings im Jahre 2024 etliche Firewalls auf
   # dem freien Markt welche genau dieses Verhalten merken, sobald eine SSH Verbindung
   # sich als harmlose https Verbindung kaschieren möchte, und werden
   # alles daran setzen diese nicht konforme Verbindung sogleich zu unterbinden.
   #
   # Zu beachten : Anstelle eines SSH-Deamons auf TCP Ports 443 kann auch eine
   # zusätzliche Wireguard Schnittstelle wg1 auf dem UDP Port 443 stehen !!!!
   # SSH benutzt nur TCP und Wireguard nur UDP als Transportprotokoll !!!
   # So kann dieser doch sehr nützlicherweise Port gleich 2x benutzt werden.
   # Unbedingt beachten : Ultra extreme Firewalls werden niemals eine Verbindung von
   # einem Client auf den UDP Port 443 zulassen, da gemäss RFC nur TCP als
   # Transportprotokoll für den zugelassen https Verker vorgesehen wurde.
   # ist ! Sollte dieses Port geblock werden bietet sich Port 123 gerdazu an.

   if [ -f ./cfg/swtor_ssh_port2 ]; then
      swtor_ssh_port2=$(cat ./cfg/swtor_ssh_port2)
   fi

   # Sollte die nachfolgende Option nicht aktiviert werden, wird es niemals
   # möglich sein eine ausgehende SSH Verbindung zu einem anderen System herzustellen.
   # Mittels iptables Firewall werden alle ausgehenden Verbindungen von diesem
   # System zu einem anderen Remote System auf den Destination TCP Port 22 geblockt.
   # Diese Option sollte wirklich nur mit allergrösster Vorsicht auf "no" gesetzt werden !!!!
   # Als Trost kann immerhin zum Loopback Device eine Verbindung hergestellt werden !
   # Aber dies dürfte von externer Seite schwer werden, sehr schwer !

   if [ -f ./cfg/swtor_allow_ssh_to_outside ]; then
     swtor_allow_ssh_to_outside="yes"
   else
     swtor_allow_ssh_to_outside="no"
   fi
else
   swtor_allow_local_ssh="no"
   swtor_ssh_port1="nicht definiert"
   swtor_ssh_port2="nicht definiert"
   swtor_allow_ssh_to_outside="nich definiert"
fi



#####################################################################
# Virtuelle Interfaces .... Wenn einfach zu wenig Schnittstellen da #
# sind müssen virtuelle Interfaces herhalten !!!                    #
# Virtuelle Interfaces eignen sich hervorragend als IPSec Endpunkte #
# und werden in diesem Fall über den Adapter eth0 erzeugt.          #
# Sie sind nicht zu verwechseln mit den virtuellen Dummy-Adaptern ! #
#####################################################################
# Alle Optionen der Virtuellen Interfaces werden über das Vorhanden #
# sein bzw. das Fehlen der nachfolgenden Dateien im Verzeichniss    #
# /etc/config/cfg bestimmt !!!                                      #
#                                                                   #
# virtual_iface                                                     #
# virtual_iface1                                                    #
# virtual_iface2                                                    #
# virtual_iface3                                                    #
#####################################################################

if [ -f ./cfg/virtual_iface ]; then
   virtual_iface="yes"

   if [ -f ./cfg/virtual_iface1 ]; then
      virtual_ifacename1="ens192:0"
      virtual_interface1=$(cat ./cfg/virtual_iface1)

      if [ -f ./cfg/virtual_subnet1 ]; then
         virtual_subnet1=$(cat ./cfg/virtual_subnet1)
      else
         echo Definition des Subnets für den Adapter 01 fehlt !
         exit 1
      fi
      virtual_iface1="yes"
   else
      virtual_iface1="no"
   fi

   if [ -f ./cfg/virtual_iface2 ]; then
      virtual_ifacename2="ens192:1"
      virtual_interface2=$(cat ./cfg/virtual_iface2)

      if [ -f ./cfg/virtual_subnet2 ]; then
         virtual_subnet2=$(cat ./cfg/virtual_subnet2)
      else
         echo Definition des Subnets für den Adapter 02 fehlt !
         exit 1
      fi
      virtual_iface2="yes"
   else
      virtual_iface2="no"
   fi

   if [ -f ./cfg/virtual_iface3 ]; then
      virtual_ifacename3="ens192:2"
      virtual_interface3=$(cat ./cfg/virtual_iface3)

      if [ -f ./cfg/virtual_subnet3 ]; then
         virtual_subnet3=$(cat ./cfg/virtual_subnet3)
      else
         echo Definition des Subnets für den Adapter 03 fehlt !
         exit 1
      fi
      virtual_iface3="yes"
   else
      virtual_iface3="no"
   fi

else

   # Da die eigentliche Hauptoption gar nicht erst aktiviert wurde ....
   # werden die 3 möglichen virtuellen Schnistellen auch gar nicht erst aktiviert !!!!

   virtual_iface="no"
   virtual_iface1="no"
   virtual_iface2="no"
   virtual_iface3="no"
fi



#########################################################################
# IPSec  .... Der sogenannte genormte Industriestandard welcher         #
# eigentlich in mehreren RFC's ziemlich exakt definiert wurde, ist mehr #
# als nur etwas zicking und wirklich sehr fehleranfällig.               #
#########################################################################
# Alle Optionen zu IPSec werden über das Vorhanden sein, bzw. das       #
# Fehlen der nachfolgenden Dateien im Verzeichniss /etc/config/cfg      #
# bestimmt !!                                                           #
#                                                                       #
# ipsec                                                                 #
# ipsec_remote                                                          #
# ipsec connection                                                      #
#########################################################################

if [ -f ./cfg/ipsec ]; then

   # Achtung : Ist das Virtuelle Interface Nummer 01 nicht aktiviert
   # kann keine IPSec Verbindung aktiviert werden !!!!

   if [ $virtual_iface1 = "no" ] ; then
      echo Lesen schadet der Dummheit !
      echo IPSec kann nicht ein ohne virtuelles Interface über eth0 betrieben werden !
      echo Das Virtuelle Interface1 wird nur für IPSec verwendet und ist nicht
      echo definiert.Die aktuell vorliegende Konfiguration ist so nicht läuffähig !
      echo RTFM and have a nice day !
      exit 1
   fi

   if [ -f /etc/ipsec.conf ]; then
      echo ipsec-suite is configured
   else
      echo Konfiguration /etc/ipsec.conf nicht vorhanden.
      echo IPSec ist nicht konfiguriert !
      exit 1
   fi

   if [ -f /etc/ipsec.secrets ]; then
      echo ipsec-suite is configured
   else
      echo Konfiguration /etc/ipsec.secrets nicht vorhanden.
      echo IPSec ist nicht konfiguriert !
      exit 1
   fi

   if [ -f /usr/sbin/ipsec ]; then
      echo strongswan is installed
   else
      echo IPSec ist nicht installiert !
      exit 1
   fi

   if [ -f ./cfg/ipsec_remote ]; then
      ipsec_remote=$(cat ./cfg/ipsec_remote)
   else
      echo ipsec_remote ist nicht definiert !
      echo RTFM and have a nice day !
      exit 1
   fi

   if [ -f ./cfg/ipsec_connection ]; then
      ipsec_connection=$(cat ./cfg/ipsec_connection)
   else
      echo ipsec_connection ist nicht definiert !
      echo Wie soll eine IPSec Verbindung aktiviert werden,
      echo wenn der Name der zu aktivierenden Verbindung nicht bekannt ist ?
      echo Dürfte etwas schwer fallen.
      echo RTFM and have a nice day !
      exit 1
   fi

   if [ -f ./cfg/ipsec_keep_alive ]; then
         remote_keep_alive=$(cat ./cfg/ipsec_keep_alive)
   else
      echo ipsec_keep_alive ist nicht definiert !
      exit 1
   fi


   swtor_use_ipsec="yes"
   ipsec down $ipsec_connection > /dev/null 2>&1

   # Ohne diesen einen Routeneintrag wüsste unser eigerner Server nicht wie er das entfernte Netz
   # erreichen kann.

   route add -net $ipsec_remote gw $external_ip > /dev/null 2>&1

else
   swtor_use_ipsec="no"
   ipsec_remote="nicht definiert"
   ipsec_connection="nicht definiert"

   # Da wir den IPSec Service ohnehin nicht benötigen ...
   # Raus mit dem Service aus dem Arbeitsspeicher

   if [ -f /etc/ipsec.conf ]; then
      systemctl stop strongswan-starter.service > /dev/null 2>&1
   fi
fi


#################################################################
# WireGuard ! Der neue Stern am Himmel der verschlüsselten      #
# Protokolle ist seit 2015 in der Entwicklung und bietet viele  #
# Vorteile und leider auch einige kleine gravierende Nachteile. #
# Das grösste Handicap von WireGuard stellt im Moment dar,dass  #
# es nicht möglich ist die IP Adressen dynamisch an Clients zu  #
# verteilen wie dies bei anderen Lösungen der Fall ist.         #
# Aus diesem Grunde darf eine gültige WireGuard Clientkonfig-   #
# konfiguration zu einem beliebigen Zeitpunkt leider immer nur  #
# auf einem Gerät aktiv sein und nicht auf mehreren             #
# gleichzeitig !                                                #
#################################################################
# Alle Optionen der WireGuard  Einstellungen werden über das    #
# Vorhanden sein bzw. Fehlen der Dateien im Verzeichniss        #
# /etc/config/cfg bestimmt und bestimmen die zu anzuwendenden   #
# Firwall Regeln                                                #
#                                                               #
# swtor_allow_wireguard1                                        #
# swtor_wireguard_port1                                         #
# wireguard_subnet1                                             #
# wireguard_interface1                                          #
# wireguard_private_routing1                                    #
#                                                               #
# swtor_allow_wireguard2                                        #
# swtor_wireguard_port2                                         #
# wireguard_subnet2                                             #
# wireguard_interface2                                          #
# wireguard_private_routing2                                    #
#################################################################

if [ -f ./cfg/swtor_allow_wireguard1 ]; then
   if [ -f ./cfg/swtor_wireguard_port1 ]; then
      swtor_wireguard_port1=$(cat ./cfg/swtor_wireguard_port1)
   else
      echo Port-Deklaration für WireGuard1 fehlt !
      echo RTFM !
      exit 1
   fi

   if [ -f ./cfg/wireguard_subnet1 ]; then
      wireguard_subnet1=$(cat ./cfg/wireguard_subnet1)
   else
      echo Subnet-Deklaration für WireGuard1 fehlt !
      echo RTFM !
      exit 1
   fi

   if [ -f ./cfg/wireguard_interface1 ]; then
      wireguard_interface1=$(cat ./cfg/wireguard_interface1)
   else
      echo Interface-Deklaration für WireGuard1 fehlt !
      echo RTFM !
      exit 1
   fi
   swtor_allow_wireguard1="yes"

   if [ -f ./cfg/wireguard_private_routing1 ]; then
       wireguard_private_routing1="yes"
   else
      wireguard_private_routing1="no"
   fi

   wireguard1_clients="172.31.255.1-172.31.255.20"
   wireguard1_do_log="no"

else
   swtor_allow_wireguard1="no"

   if [ $redirect_wg0_to_socks5 = "yes" ] ; then
      echo redirect_wg0_to_socks funktioniert nur mit aktivertem  WireGuard1 !
      echo RTFM !
      exit 1
   fi
fi

if [ -f ./cfg/swtor_allow_wireguard2 ]; then
   if [ -f ./cfg/swtor_wireguard_port2 ]; then
      swtor_wireguard_port2=$(cat ./cfg/swtor_wireguard_port2)
   else
      echo Port-Deklaration für WireGuard2 fehlt !
      echo RTFM !
      exit 1
   fi

   if [ -f ./cfg/wireguard_subnet2 ]; then
      wireguard_subnet2=$(cat ./cfg/wireguard_subnet2)
   else
      echo Subnet-Deklaration für WireGuard2 fehlt !
      echo RTFM !
      exit 1
   fi

   if [ -f ./cfg/wireguard_interface2 ]; then
      wireguard_interface2=$(cat ./cfg/wireguard_interface2)
   else
      echo Interface-Deklaration für WireGuard2 fehlt !
      echo RTFM !
      exit 1
   fi
   swtor_allow_wireguard2="yes"

   if [ -f ./cfg/wireguard_private_routing2 ]; then
       wireguard_private_routing2="yes"
   else
      wireguard_private_routing2="no"
   fi

   wireguard2_clients="172.30.255.1-172.30.255.20"
   wireguard2_do_log="no"

else
   swtor_allow_wireguard2="no"
fi

# Das Forwarding aktivieren und alles IP V6 Gesockse in die Wüste schicken ......

/sbin/sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
/sbin/sysctl -w net.ipv4.conf.all.accept_redirects=0 > /dev/null 2>&1
/sbin/sysctl -w net.ipv4.conf.all.send_redirects=0 > /dev/null 2>&1

# Achtung : ohne diese kleine Anweisung lassen sich die Packete nicht auf
# localhost umbiegen !

/sbin/sysctl -w net.ipv4.conf.all.route_localnet=1 > /dev/null 2>&1

/sbin/sysctl -w net.ipv4.conf.all.arp_ignore=1 > /dev/null 2>&1
/sbin/sysctl -w net.ipv4.conf.all.arp_announce=2 > /dev/null 2>&1
/sbin/sysctl -w net.ipv4.conf.all.rp_filter=2 > /dev/null 2>&1


# Sollte der GRUB Bootparameter nicht wirksam sein ...
# Auch so lässt sich IP V6 wirksam ausschalten.

#/sbin/sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
#/sbin/sysctl -w net.ipv6.conf.all.autoconf=0 > /dev/null 2>&1
#/sbin/sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null 2>&1


echo [ip-tables  :  reset tables]
/usr/sbin/iptables -P INPUT ACCEPT
/usr/sbin/iptables -P FORWARD ACCEPT
/usr/sbin/iptables -P OUTPUT ACCEPT
/usr/sbin/iptables -t nat -F
/usr/sbin/iptables -t mangle -F
/usr/sbin/iptables -F
/usr/sbin/iptables -X
echo [ip-tables  :  reset is made]


echo [ip-tables : calculate used networks ]

if [ $swtor_use_ipsec = "yes" ] ; then
   used_internal="$(echo $ipsec_remote),$(echo $virtual_interface1)"
   if [ $virtual_iface2 = "yes" ] ; then
      used_internal="$(echo $used_internal),$(echo $virtual_interface2)"
   fi
   if [ $virtual_iface3 = "yes" ] ; then
      used_internal="$(echo $used_internal),$(echo $virtual_interface3)"
   fi
else

   used_internal="127.0.0.1"

   # Achtung : Da es möglich ist, eines der 2 beiden virtuellen Interfaces
   # ens192:1 oder ens192:2 auch ohne die explizite Aktivierung von IPSec zu betreiben,
   # wird auch dieser Fall abgefangen !

   if [ $virtual_iface2 = "yes" ] ; then
      used_internal="$(echo $used_internal),$(echo $virtual_interface2)"
   fi

   if [ $virtual_iface3 = "yes" ] ; then
      used_internal="$(echo $used_internal),$(echo $virtual_interface3)"
   fi

fi

if [ $swtor_allow_wireguard1 = "yes" ] ; then
   used_internal="$(echo $used_internal),$(echo $wireguard_subnet1)"
fi

if [ $swtor_allow_wireguard2 = "yes" ] ; then
   used_internal="$(echo $used_internal),$(echo $wireguard_subnet2)"
fi

if [ $using_pihole = "yes" ]; then
   used_internal="$(echo $used_internal),$(echo $pihole_ip)"
fi

if [ $swtor_use_ipsec = "yes" ] ; then
   /usr/sbin/iptables -A FORWARD -p icmp  -d $ipsec_remote -j ACCEPT
   /usr/sbin/iptables -A OUTPUT -p icmp -d $ipsec_remote -j ACCEPT
fi


echo [ip-tables : Detect bad packets as soon as possible ]

# zu beachten : Genau in diese vordefinierte iptables Kette kommen solche schrägen Packete eigentlich
# genau hin. Wer diese ungültigen Packete wie an so vielen Orten und Beispielen zu finden in der INPUT
# Kette platziert hat die fundamentalsten Grundprinzipien von iptables nicht wirklich verstanden !
# Auch zu diesem sehr komplexen Thema gibt es wirklich ausgezeichnete Bücher !

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j LOG --log-prefix "chain01/01 "
fi
iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP \
-m comment --comment "chain 01/01 block uncommon mss values"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p all -m conntrack --ctstate INVALID -j LOG --log-prefix "chain01/02 "
fi
iptables -t mangle -A PREROUTING -p all -m conntrack --ctstate INVALID -j DROP  \
-m comment --comment "chain 01/02 block invalid packets"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j LOG --log-prefix "chain01/03 "
fi
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP \
-m comment --comment "chain 01/03 block not-syn flag marked packets"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN,URG,NONE -j LOG --log-prefix "chain01/04 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN,URG,NONE -j DROP \
-m comment --comment "chain 01/04 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j LOG  --log-prefix "chain01/05 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP \
-m comment --comment "chain 01/05 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j LOG  --log-prefix "chain01/06 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP \
-m comment --comment "chain 01/06 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,FIN SYN,FIN -j LOG  --log-prefix "chain01/07 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP \
-m comment --comment "chain 01/07 block packets with bogus tcp flags"


if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j LOG  --log-prefix "chain01/08 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP \
-m comment --comment "chain 01/08 block packets with bogus tcp flags"


if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j LOG  --log-prefix "chain01/09 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP \
-m comment --comment "chain 01/09 block packets with bogus tcp flags"


if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j LOG  --log-prefix "chain01/10 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP \
-m comment --comment "chain 01/10 block packets with bogus tcp flags"


if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j LOG  --log-prefix "chain01/11 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP \
-m comment --comment "chain 01/11 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j LOG  --log-prefix "chain01/12 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP \
-m comment --comment "chain 01/12 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j LOG  --log-prefix "chain01/13 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP \
-m comment --comment "chain 01/13 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j LOG  --log-prefix "chain01/14 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP \
-m comment --comment "chain 01/14 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j LOG  --log-prefix "chain01/15 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP \
-m comment --comment "chain 01/15 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j LOG  --log-prefix "chain01/16 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP \
-m comment --comment "chain 01/16 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j LOG  --log-prefix "chain01/17 "
fi
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP \
-m comment --comment "chain 01/17 block packets with bogus tcp flags"

if [ $fw_debug = "yes" ] ; then
iptables -t mangle -A PREROUTING -f -j LOG  --log-prefix "chain01/18 "
fi
iptables -t mangle -A PREROUTING -f -j DROP \
-m comment --comment "chain 01/18 block fragmented packets"


echo [ip-tables : allow all traffic on loopback interface 127.0.0.1]
/usr/sbin/iptables -A INPUT   -i lo        -p all -j ACCEPT
/usr/sbin/iptables -A OUTPUT  -o lo        -p all -j ACCEPT
/usr/sbin/iptables -A FORWARD -i lo        -o $external_if  -j ACCEPT
/usr/sbin/iptables -A FORWARD -i $external_if -o lo -j ACCEPT

if [ $virtual_iface = "yes" ] ; then
   if [ $virtual_iface2 = "yes" ] ; then
      /usr/sbin/iptables -I OUTPUT -o $virtual_ifacename2  -d 0.0.0.0/0 -j ACCEPT
      /usr/sbin/iptables -I INPUT  -i $virtual_ifacename2  -m state --state NEW,ESTABLISHED,RELATED
      /usr/sbin/iptables -A FORWARD -i $virtual_ifacename2 -o lo  -j ACCEPT
      /usr/sbin/iptables -A FORWARD -i lo -o $virtual_ifacename2 -j ACCEPT
   fi
   if [ $virtual_iface3 = "yes" ] ; then
      /usr/sbin/iptables -I OUTPUT -o $virtual_ifacename3  -d 0.0.0.0/0 -j ACCEPT
      /usr/sbin/iptables -I INPUT -i $virtual_ifacename3  -m state --state NEW,ESTABLISHED,RELATED
      /usr/sbin/iptables -A FORWARD -i $virtual_ifacename3 -o lo  -j ACCEPT
      /usr/sbin/iptables -A FORWARD -i lo -o $virtual_ifacename3 -j ACCEPT
   fi
fi


echo [ip-tables : allowed traffic from and to eth0 ]

/usr/sbin/iptables -A INPUT -s $external_ip -j DROP
/usr/sbin/iptables -I INPUT -i $external_if -m state --state ESTABLISHED,RELATED -j ACCEPT

if [ $using_snowflake = "yes" ] ; then

   # Ist zwar etwas unschön einen solchen grossen UDP Bereich einfach so zu öffnen
   # aber es geht leider nicht anders ... weil sonst der snowflake-proxy
   # von einer NAT Verbindung aus geht !

   /usr/sbin/iptables -A FORWARD -p udp --dport 32768:60999 -j ACCEPT
   /usr/sbin/iptables -A INPUT -p udp --dport 32768:60999 -j ACCEPT

   if [ $virtual_iface1 = "yes" ] ; then
      /usr/sbin/iptables -A FORWARD -i $virtual_ifacename1 -o $external_if  -j ACCEPT
      /usr/sbin/iptables -A FORWARD -i $external_if -o $virtual_ifacename1  -j ACCEPT

      /usr/sbin/iptables -t nat -A POSTROUTING -s $used_internal -d $ipsec_remote  -j SNAT --to $virtual_interface1
      /usr/sbin/iptables -t nat -A POSTROUTING -s $virtual_interface1 -d 0.0.0.0/0  -j SNAT --to $external_ip
   fi

   if [ $virtual_iface2 = "yes" ] ; then
      /usr/sbin/iptables -A FORWARD -i $virtual_ifacename2 -o $external_if  -j ACCEPT
      /usr/sbin/iptables -A FORWARD -i $external_if -o $virtual_ifacename2  -j ACCEPT
      /usr/sbin/iptables -t nat -A POSTROUTING -s $virtual_interface2 -d 0.0.0.0/0  -j SNAT --to $external_ip
   fi

   if [ $using_pihole = "yes" ] ; then
      /usr/sbin/iptables -A FORWARD -i tun0 -o $external_if  -j ACCEPT
      /usr/sbin/iptables -A FORWARD -i $external_if -o tun0  -j ACCEPT
      /usr/sbin/iptables -t nat -A POSTROUTING -s $pihole_ip -d 0.0.0.0/0  -j SNAT --to $external_ip
   fi
fi

echo [ip-tables : allow only ICMP packetes that came from this server]

# Wir akzeptieren nur ICMP Packete von unserem eigenen Server, alle anderen Packete werden verworfen

/usr/sbin/iptables -A INPUT -p icmp --icmp-type 0 -s 0/0 -d $external_ip -m state --state ESTABLISHED,RELATED -j ACCEPT
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 0 -j LOG  --log-prefix "input icmp type 0"
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 0 -j DROP


/usr/sbin/iptables -A INPUT -p icmp --icmp-type 1 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 2 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 3 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 4 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 5 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 6 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 7 -j DROP


if [ $virtual_iface1 = "yes" ] ; then
   if [ $swtor_allow_wireguard1 = "yes" ] ; then
      if [ $swtor_use_ipsec = "yes" ] ; then
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet1 -d $ipsec_remote  -j ACCEPT
      else
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet1 -d $virtual_interface1  -j ACCEPT
      fi
   fi

   if [ $swtor_allow_wireguard2 = "yes" ] ; then
      if [ $swtor_use_ipsec = "yes" ] ; then
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet2 -d $ipsec_remote -j ACCEPT
      else
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet2 -d $virtual_interface1  -j ACCEPT
      fi
   fi
fi


if [ $virtual_iface2 = "yes" ] ; then
   if [ $swtor_allow_wireguard1 = "yes" ] ; then
      if [ $swtor_use_ipsec = "yes" ] ; then
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet1 -d $ipsec_remote  -j ACCEPT
      else
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet1 -d $virtual_interface2  -j ACCEPT
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet1 -d $wireguard_subnet1  -j ACCEPT

      fi
   fi

   if [ $swtor_allow_wireguard2 = "yes" ] ; then
      if [ $swtor_use_ipsec = "yes" ] ; then
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet2 -d $ipsec_remote -j ACCEPT
      else
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet2 -d $virtual_interface2  -j ACCEPT
         /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
         -s $wireguard_subnet2 -d $wireguard_subnet2  -j ACCEPT
      fi
   fi
fi


if [ $using_pihole = "yes" ]; then
    /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 \
    -s $pihole_ip -d $ipsec_remote  -j ACCEPT
    /usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 -d $pihole_ip -j ACCEPT
fi

if [ $swtor_use_ipsec = "yes" ] ; then
   /usr/sbin/iptables -A INPUT  -p icmp --icmp-type 8 -d $virtual_interface1 -j ACCEPT
fi

/usr/sbin/iptables -A INPUT -p icmp --icmp-type 8 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 9 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 10 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 11 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 12 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 13 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 14 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 15 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 16 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 17 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 18 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 19 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 20 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 21 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 22 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 23 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 24 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 25 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 26 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 27 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 28 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 29 -j DROP
/usr/sbin/iptables -A INPUT -p icmp --icmp-type 30 -j DROP

# Hier wird definiert .... was das OUTPUT verlassen darf.
# Bei ICMP wird nur ping (type 8) unterstützt. Der Rest wird geblockt.
# Unter gar keinen Umständen wird ein Packet mit der Zielrichtung
# UDP Port 53 diesen Server verlassen.
# Der Rest ist im Moment noch ziemlich egal ......

if [ $virtual_iface1 = "yes" ] ; then
   if [ $swtor_use_ipsec = "yes" ] ; then
      /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 0 \
      -s $virtual_interface1 -d $ipsec_remote -j ACCEPT
  fi
fi

if [ $virtual_iface2 = "yes" ] ; then
   if [ $swtor_allow_wireguard1 = "yes" ] ; then
      if [ $swtor_use_ipsec = "yes" ] ; then
         /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 0 \
         -s $wireguard_subnet1,$virtual_interface2,$pihole_ip -d $ipsec_remote -j ACCEPT
      else
         /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 0 \
         -s $wireguard_subnet1,$virtual_interface2 -d 0.0.0.0/0 -j ACCEPT
      fi
   fi

   if [ $swtor_allow_wireguard2 = "yes" ] ; then
      if [ $swtor_use_ipsec = "yes" ] ; then
         /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 0 \
         -s $wireguard_subnet2,$virtual_interface2,$pihole_ip -d $ipsec_remote -j ACCEPT
      else
         /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 0 \
         -s $wireguard_subnet2,$virtual_interface2 -d 0.0.0.0/0 -j ACCEPT
      fi
   fi
fi


if [ $do_log_icmp = "yes" ] ; then
   /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 0 -j LOG  --log-prefix "output icmp type 0"
   /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 0 -j DROP
fi

/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 1 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 2 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 3 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 4 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 5 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 6 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 7 -j DROP


if [ $swtor_use_ipsec = "yes" ] ; then
    /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 8 -s $virtual_interface1 -d $ipsec_remote -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
fi

if [ $swtor_use_ipsec = "yes" ] ; then
   /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 8 -s $external_ip -d $ipsec_remote -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
fi

/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 8 -s $external_ip -d 0/0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT


if [ $do_log_icmp = "yes" ] ; then
   /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 8 -j LOG --log-level warning --log-prefix "OUTPUT ICMP DROP "
   /usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 8 -j DROP
fi

/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 9  -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 10 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 11 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 12 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 13 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 14 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 15 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 16 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 17 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 18 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 19 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 20 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 21 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 22 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 23 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 24 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 25 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 26 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 27 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 28 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 29 -j DROP
/usr/sbin/iptables -A OUTPUT -p icmp --icmp-type 30 -j DROP

if [ $redirect_wg0_to_socks5 = "yes" ] ; then

    # Unser lokales Testscript vom Localhost muss umgeleitet werden
    # curl --interface 127.0.0.1 https://www.heise.de

    /usr/sbin/iptables -t nat -A OUTPUT -d 193.99.144.85 -p tcp \
    --dport 80 -j DNAT --to-destination $redirect_wg0

    /usr/sbin/iptables -t nat -A OUTPUT -d 193.99.144.85 -p tcp \
    --dport 443 -j DNAT --to-destination $redirect_wg0

fi



/usr/sbin/iptables -A OUTPUT -o $external_if -d 0.0.0.0/0 -j ACCEPT

# Genau hier findet die grosse Show statt. Beim verlassen des Tunnels werden
# alle Packete an dieser Stelle landen. Und genau hier werden alle Packete die
# eigentlich über die Schnittstelle eth0 den Rechner direkt verlassen sollten,
# mit etwas Magie verunstaltet.


if [ $redirect_wg0_to_socks5 = "yes" ] ; then


   # Alles was für das entfernte Netzwerk über IPSec bestimmt ist, wird direkt in
   # die nächste Kette geleitet. Keine Magie für diese Packete

   if [ $swtor_use_ipsec = "yes" ] ; then
      if [ $virtual_iface1 = "yes" ] ; then
         /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -d $ipsec_remote  -j RETURN
      fi
   fi

   # Wir wollen uns nicht selbst in den Fuss schiessen .... SSH wird einfach durchgereicht
   # Ohne diese Regel müssten wir ständig das VPN deaktivieren um in Kontakt mit dem
   # Server zu treten.Das Webinterface von Pihole inkl. dem Resolver muss ebenfalls erreichbar bleiben
   # Und selbstverständlich muss auch das lauschende TOR-Interface erreichbar sein

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp --dport 22  -j RETURN

   if [ $using_tor = "yes" ] ; then
      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp --dport $tor_port -j RETURN
   fi

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p icmp -j RETURN

   if [ $using_pihole = "yes" ]; then

      # Webinterface von Pihole

      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -d $pihole_ip -p udp \
      --dport 80 -j RETURN
      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -d $pihole_ip -p tcp \
      --dport 80 -j RETURN

      # DNS von Pihole

      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -d $pihole_ip -p udp \
      --dport 53 -j RETURN
      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -d $pihole_ip -p tcp \
      --dport 53 -j RETURN

   else

     # DNS von Wirguard1 (ohne Pihole)

     /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p udp \
     --dport 53 -d $wireguard1_dns -j RETURN
     /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
     --dport 53 -d $wireguard1_dns -j RETURN

     /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p udp \
     --dport 53 -d 0.0.0.0 -j LOG --log-prefix "WG0 OUTPUT DNS-TRAPPED UDP"
     /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p udp \
     --dport 53 -d 0.0.0.0 -j DNAT --to-destination $wireguard1_dns:53

     /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
     --dport 53 -d 0.0.0.0 -j LOG --log-prefix "WG0 OUTPUT DNS-TRAPPED TCP"
     /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
     --dport 53 -d 0.0.0.0  -j DNAT --to-destination $wireguard1_dns:53

   fi

   # Hier leiten wir den gesamten Port 80 und 443 auf den lokalen Port 1081 um.

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 80 -j DNAT --to-destination $redirect_wg0
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p udp \
   --dport 80 -j DNAT --to-destination $redirect_wg0

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 443 -j DNAT --to-destination $redirect_wg0
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p udp \
   --dport 443 -j DNAT --to-destination $redirect_wg0

   # An dieser Stelle werden die wohl wichtigsten Ports unter dem Bereich 1024 umgleitet.

   # Port 25 und 110 die unverschlüsselten Urgesteine der SMTP Kommunikation

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 25 -j DNAT --to-destination $redirect_wg0
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 110 -j DNAT --to-destination $redirect_wg0

   # Heute werden wir wohl diese beiden Ports brauchen

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 465 -j DNAT --to-destination $redirect_wg0
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 587  -j DNAT --to-destination $redirect_wg0

   # IMAP

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 143 -j DNAT --to-destination $redirect_wg0
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 993 -j DNAT --to-destination $redirect_wg0

   # POP3S

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 995 -j DNAT --to-destination $redirect_wg0

   # DNS over TLS

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 853 -j DNAT --to-destination $redirect_wg0

   # FTPS

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 989 -j DNAT --to-destination $redirect_wg0
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 990 -j DNAT --to-destination $redirect_wg0

   # Android Chrome Browser / WhatsApp
   # [ 1467.758443] WG0 OUTPUT TCP DPT=5228 WINDOW=65535 RES=0x00 SYN URGP=0
   # [ 1468.228390] WG0 OUTPUT TCP DPT=5222 WINDOW=65535 RES=0x00 SYN URGP=0

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 5222 -j DNAT --to-destination $redirect_wg0
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
   --dport 5228 -j DNAT --to-destination $redirect_wg0

   # NTP

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p udp \
   --dport 123 -j DNAT --to-destination $redirect_wg0

   # Da wir noch nicht genau wissen, welcher der beiden TCP auf Socks5 Comverter
   # unter Debian 12 nun eigentlich besser läuft, beginnen wir mal mit dem redsocks converter
   # Gewisse Webseiten wie zum Beispiel google laufen auch in der aktuellen Konfiguration nicht
   # wirklich richtig. Ich vermute es müssen noch vereinzelne Ports umgeleitet werden.
   # Um zu wissen, was genau über den Kanal läuft, loggen wir mal zur Sicherheit alles.
   # Auch der redirector redsocks scheint seine eigenen kleinen Probleme zu haben.

   if [ $wireguard1_do_log = "yes" ] ; then

      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p udp \
      -j LOG --log-level warning --log-prefix "WG0 OUTPUT UDP "
      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p udp \
      -j RETURN

      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
      -j LOG --log-level warning --log-prefix "WG0 OUTPUT TCP "
      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard1_clients -p tcp \
      -j RETURN
   fi

fi

if [ $swtor_allow_wireguard1 = "yes" ] ; then

   # Alles was für externe Adressen bestimmt ist und auch die lokalen privaten Adressen dürfen passieren

   /usr/sbin/iptables -A FORWARD -m iprange  --src-range $wireguard1_clients -p icmp -d $used_internal -j ACCEPT
   /usr/sbin/iptables -A FORWARD -m iprange  --src-range $wireguard1_clients -p udp -d $used_internal -j ACCEPT
   /usr/sbin/iptables -A FORWARD -m iprange  --src-range $wireguard1_clients -p tcp -d $used_internal -j ACCEPT

   # Loopback
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -d 127.0.0.0/8 -j REJECT
   # APIPA
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -d 169.254.0.0/16 -j REJECT
   # Unicast und Mutlicast
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -d 224.0.0.0/4 -j REJECT
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -d 240.0.0.0/4 -j REJECT
   # Privater Klasse A Bereich
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -d 10.0.0.0/8 -j REJECT
   # Privater Klasse B Bereich
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -d 172.16.0.0/12 -j REJECT
   # Privater Klasse C Bereich
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -d 192.168.0.0/16 -j REJECT


   if [ $redirect_wg0_to_socks5 = "yes" ] ; then

      /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -p tcp \
      --dport 22  -j ACCEPT

      # Hier ist die Reise der Packete welche WG0 verlassen zu Ende sofern die Umleitung aktiviert ist
      # UDP / TCP 53 und HTTP und HTTPS werden umgeleitet auf den lokalen Socks5 Server

      /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -p udp \
      -j REJECT
      /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -p tcp \
      -j REJECT

   else

      # Der übrige IP-Bereich darf den Filter verlassen

      /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard1_clients -d 0.0.0.0 -j ACCEPT

   fi
fi


if [ $swtor_allow_wireguard2 = "yes" ] ; then

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p udp \
    --dport 53 -d $wireguard2_dns -j RETURN
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p tcp \
    --dport 53 -d $wireguard2_dns -j RETURN

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p udp \
    --dport 53 -d 0.0.0.0 -j LOG --log-prefix "WG1 OUTPUT DNS-TRAPPED UDP"
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p udp \
    --dport 53 -d 0.0.0.0 -j DNAT --to-destination $wireguard2_dns:53

   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p tcp \
    --dport 53 -d 0.0.0.0 -j LOG --log-prefix "WG1 OUTPUT DNS-TRAPPED TCP"
   /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p tcp \
    --dport 53 -d 0.0.0.0  -j DNAT --to-destination $wireguard2_dns:53


   if [ $wireguard2_do_log = "yes" ] ; then

      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p icmp \
      -j LOG --log-level warning --log-prefix "WG1 OUTPUT ICMP "
      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p icmp \
      -j RETURN

      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p udp \
      -j LOG --log-level warning --log-prefix "WG1 OUTPUT UDP "
      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p udp \
      -j RETURN

      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p tcp \
      -j LOG --log-level warning --log-prefix "WG1 OUTPUT TCP "
      /usr/sbin/iptables -t nat -A PREROUTING -m iprange --src-range $wireguard2_clients -p tcp \
      -j RETURN
   fi

   # Alles was für externe Adressen bestimmt ist und auch die lokalen privaten Adressen dürfen passieren

   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d $used_internal -j ACCEPT

   # Loopback
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d 127.0.0.0/8 -j REJECT
   # APIPA
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d 169.254.0.0/16 -j REJECT
   # Unicast und Mutlicast
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d 224.0.0.0/4 -j REJECT
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d 240.0.0.0/4 -j REJECT
   # Privater Klasse A Bereich
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d 10.0.0.0/8 -j REJECT
   # Privater Klasse B Bereich
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d 172.16.0.0/12 -j REJECT
   # Privater Klasse C Bereich
   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d 192.168.0.0/16 -j REJECT

   # Der übrige IP-Bereich darf den Filter verlassen

   /usr/sbin/iptables -A FORWARD -m iprange --src-range $wireguard2_clients -d 0.0.0.0 -j ACCEPT

fi

echo [ip-tables : block all external communication to port 53 udp and tcp ]
iptables -A FORWARD -o $external_if -p tcp --dport 53 -j REJECT
iptables -A FORWARD -o $external_if -p udp --dport 53 -j REJECT


echo [ip-tables : allow udp-block reject to traceroute]
iptables -A INPUT -p udp --dport 33434:33474 -j REJECT

echo [ip-tables : Allow DHCP / UDP on port 67/68 on interface eth0]
/usr/sbin/iptables -A INPUT  -i $external_if -p udp --sport 68 --dport 67 -j ACCEPT
/usr/sbin/iptables -A OUTPUT -o $external_if -p udp --sport 67 --dport 68 -j ACCEPT
/usr/sbin/iptables -A INPUT  -i $external_if -p udp --sport 67 --dport 68 -j ACCEPT
/usr/sbin/iptables -A OUTPUT -o $external_if -p udp --sport 68 --dport 67 -j ACCEPT

if [ $virtual_iface = "yes" ] ; then

   if [ $virtual_iface1 = "yes" ] ; then
      echo [ip-tables : allow internal interface 01]
      /usr/sbin/iptables -A INPUT  -i $virtual_ifacename1 -p all -j ACCEPT
      /usr/sbin/iptables -A OUTPUT -o $virtual_ifacename1 -p all -j ACCEPT
      /usr/sbin/iptables -A INPUT  -i $virtual_ifacename1  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
      /usr/sbin/iptables -A OUTPUT -o $virtual_ifacename1  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
      if [ $using_snowflake = "no" ] ; then
         /usr/sbin/iptables -A FORWARD -i $virtual_ifacename1 -o $external_if  -j ACCEPT
         /usr/sbin/iptables -A FORWARD -i $external_if -o $virtual_ifacename1 -j ACCEPT
      fi
   fi

   if [ $virtual_iface2 = "yes" ] ; then
      echo [ip-tables : allow internal interface 02]
       /usr/sbin/iptables -A INPUT  -i $virtual_ifacename2 -p all -j ACCEPT
       /usr/sbin/iptables -A OUTPUT -o $virtual_ifacename2 -p all -j ACCEPT
       /usr/sbin/iptables -A INPUT  -i $virtual_ifacename2  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
       /usr/sbin/iptables -A OUTPUT -o $virtual_ifacename2  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
       if [ $using_snowflake = "no" ] ; then
          /usr/sbin/iptables -A FORWARD -i $virtual_ifacename2 -o $external_if  -j ACCEPT
          /usr/sbin/iptables -A FORWARD -i $external_if -o $virtual_ifacename2 -j ACCEPT
          /usr/sbin/iptables -t nat -A POSTROUTING -s $virtual_interface2 -d 0.0.0.0/0  -j SNAT --to $external_ip
       fi
   fi

   if [ $virtual_iface3 = "yes" ] ; then
      echo [ip-tables : allow internal interface 03]
       /usr/sbin/iptables -A INPUT  -i $virtual_ifacename3 -p all -j ACCEPT
       /usr/sbin/iptables -A OUTPUT -o $virtual_ifacename3 -p all -j ACCEPT
       /usr/sbin/iptables -A INPUT  -i $virtual_ifacename3  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
       /usr/sbin/iptables -A OUTPUT -o $virtual_ifacename3  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
       if [ $using_swnowflake = "no" ] ; then
          /usr/sbin/iptables -A FORWARD -i $virtual_ifacename3 -o $external_if  -j ACCEPT
          /usr/sbin/iptables -A FORWARD -i $external_if -o $virtual_ifacename3 -j ACCEPT
          /usr/sbin/iptables -t nat -A POSTROUTING -s $virtual_interface3 -d 0.0.0.0/0  -j SNAT --to $external_ip
       fi
   fi
fi


if [ $swtor_allow_wireguard1 = "yes" ] ; then
   echo [ip-tables : allow interface wg0 ]
   /usr/sbin/iptables -A INPUT  -i $wireguard_interface1 -p all -j ACCEPT
   /usr/sbin/iptables -A OUTPUT -o $wireguard_interface1 -p all -j ACCEPT
   /usr/sbin/iptables -A INPUT  -i $wireguard_interface1  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
   /usr/sbin/iptables -A OUTPUT -o $wireguard_interface1  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
   /usr/sbin/iptables -A FORWARD -i $wireguard_interface1 -o $external_if  -j ACCEPT
   /usr/sbin/iptables -A FORWARD -i $external_if -o $wireguard_interface1 -j ACCEPT

   /usr/sbin/iptables -A FORWARD -i $wireguard_interface1 -o lo  -j ACCEPT
   /usr/sbin/iptables -A FORWARD -i lo -o $wireguard_interface1 -j ACCEPT

   if [ $using_pihole = "yes" ] ; then
      /usr/sbin/iptables -A FORWARD -i $wireguard_interface1 -o $pihole_interface  -j ACCEPT
      /usr/sbin/iptables -A FORWARD -i $pihole_interface -o $wireguard_interface1 -j ACCEPT
   fi

   if [ $virtual_iface = "yes" ] ; then
      if [ $virtual_iface1 = "yes" ] ; then
         /usr/sbin/iptables -A FORWARD -i $wireguard_interface1 -o $virtual_ifacename1  -j ACCEPT
         /usr/sbin/iptables -A FORWARD -i $virtual_ifacename1 -o $wireguard_interface1 -j ACCEPT
      fi
      if [ $virtual_iface2 = "yes" ] ; then
         /usr/sbin/iptables -A FORWARD -i $wireguard_interface1 -o $virtual_ifacename2  -j ACCEPT
         /usr/sbin/iptables -A FORWARD -i $virtual_ifacename2 -o $wireguard_interface1 -j ACCEPT
      fi
      if [ $virtual_iface3 = "yes" ] ; then
         /usr/sbin/iptables -A FORWARD -i $wireguard_interface1 -o $virtual_ifacename3  -j ACCEPT
         /usr/sbin/iptables -A FORWARD -i $virtual_ifacename3 -o $wireguard_interface1 -j ACCEPT
      fi
   fi
fi

if [ $swtor_allow_wireguard2 = "yes" ] ; then
   echo [ip-tables : allow interface wg1  ]
   /usr/sbin/iptables -A INPUT  -i $wireguard_interface2 -p all -j ACCEPT
   /usr/sbin/iptables -A OUTPUT -o $wireguard_interface2 -p all -j ACCEPT
   /usr/sbin/iptables -A INPUT  -i $wireguard_interface2  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
   /usr/sbin/iptables -A OUTPUT -o $wireguard_interface2  -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
   /usr/sbin/iptables -A FORWARD -i $wireguard_interface2 -o $external_if  -j ACCEPT
   /usr/sbin/iptables -A FORWARD -i $external_if -o $wireguard_interface2 -j ACCEPT

   /usr/sbin/iptables -A FORWARD -i $wireguard_interface2 -o lo  -j ACCEPT
   /usr/sbin/iptables -A FORWARD -i lo -o $wireguard_interface2 -j ACCEPT

   if [ $using_pihole = "yes" ] ; then
      /usr/sbin/iptables -A FORWARD -i $wireguard_interface2  -o $pihole_interface  -j ACCEPT
      /usr/sbin/iptables -A FORWARD -i $pihole_interface -o $wireguard_interface2 -j ACCEPT
   fi

   if [ $virtual_iface = "yes" ] ; then
      if [ $virtual_iface1 = "yes" ] ; then
         /usr/sbin/iptables -A FORWARD -i $wireguard_interface2 -o $virtual_ifacename1  -j ACCEPT
         /usr/sbin/iptables -A FORWARD -i $virtual_ifacename1 -o $wireguard_interface2 -j ACCEPT
      fi
      if [ $virtual_iface2 = "yes" ] ; then
         /usr/sbin/iptables -A FORWARD -i $wireguard_interface2 -o $virtual_ifacename2  -j ACCEPT
         /usr/sbin/iptables -A FORWARD -i $virtual_ifacename2 -o $wireguard_interface2 -j ACCEPT
      fi
      if [ $virtual_iface3 = "yes" ] ; then
         /usr/sbin/iptables -A FORWARD -i $wireguard_interface2 -o $virtual_ifacename3  -j ACCEPT
         /usr/sbin/iptables -A FORWARD -i $virtual_ifacename3 -o $wireguard_interface2 -j ACCEPT
      fi
   fi
fi

if [ $swtor_allow_wireguard1 = "yes" ] ; then
   echo [ip-tables : starting wireguard wg0]

   systemctl start wg-quick@wg0 > /dev/null

   if [ $using_pihole = "no" ]; then
      systemctl stop stubby > /dev/null
      systemctl start stubby > /dev/null
   fi

   # Sobald eine IPSec Verbindung aktiv ist -> Kann Wireguard auf dieses Netzwerk zugreifen

   if [ $swtor_use_ipsec = "yes" ] ; then
      if [ $virtual_iface1 = "yes" ] ; then
         /usr/sbin/iptables -t nat -A POSTROUTING -s $wireguard_subnet1 -d $ipsec_remote  -j SNAT --to $virtual_interface1
      fi
   fi

   if [ $wireguard_private_routing1 = "no" ] ; then

      # Standard : /usr/sbin/iptables -t nat -A POSTROUTING -s $wireguard_subnet1 -d 0.0.0.0/0  -j SNAT --to $external_ip

      /usr/sbin/iptables -t nat -A POSTROUTING -s $wireguard_subnet1 -d 0.0.0.0/0  -j SNAT --to $external_ip

   fi

   if [ $wireguard_private_routing1 = "yes" ] ; then
      echo
      ##############################################################################################################
      ##############################################################################################################
   fi

fi


if [ $swtor_allow_wireguard2 = "yes" ] ; then
   echo [ip-tables : starting wireguard wg1]

   systemctl start wg-quick@wg1 > /dev/null

   if [ $using_pihole = "no" ]; then
      systemctl stop stubby > /dev/null
      systemctl start stubby > /dev/null
   fi

   # Sobald eine IPSec Verbindung aktiv ist -> Kann Wireguard auf dieses Netzwerk zugreifen

   if [ $swtor_use_ipsec = "yes" ] ; then
      if [ $virtual_iface1 = "yes" ] ; then
         /usr/sbin/iptables -t nat -A POSTROUTING -s $wireguard_subnet2 -d $ipsec_remote  -j SNAT --to $virtual_interface1
      fi
   fi

   if [ $wireguard_private_routing2 = "no" ] ; then

      # Standard : /usr/sbin/iptables -t nat -A POSTROUTING -s $wireguard_subnet2 -d 0.0.0.0/0  -j SNAT --to $external_ip

      /usr/sbin/iptables -t nat -A POSTROUTING -s $wireguard_subnet2 -d 0.0.0.0/0  -j SNAT --to $external_ip

   fi

   if [ $wireguard_private_routing2 = "yes" ] ; then
      echo
      ##############################################################################################################
      ##############################################################################################################
   fi

fi


if [ $redirect_wg0_to_socks5 = "yes" ] ; then
   if [ $virtual_iface2 = "yes" ] ; then

   cd /etc/config/scripts

   # Bevor wir dieses Script starten ... sollten alle Instanzen
   # der Scripts im Zusammenhang mit redirect auch wirklich beendet werden.

   killall -u $redirect_user_socks5 > /dev/null 2>&1
   killall ssh-v.sh > /dev/null 2>&1

   ./ssh-v.sh $(echo $redirect_user_socks5 $redirect_command) > /etc/config/scripts/ssh.log 2>&1 &

   fi
fi

if [ $swtor_allow_local_ssh = "yes" ] ; then
   if [ -z "$swtor_ssh_port1" ] ; then
       echo [ip-tables : ssh port 1 not defined ]
   else
       echo [ip-tables : Allow new incomming SSH / TCP port 22 on interface eth0 ]
       /usr/sbin/iptables -A INPUT  -i $external_if -m state --state NEW,ESTABLISHED -p tcp --dport $swtor_ssh_port1 -j ACCEPT
       /usr/sbin/iptables -A OUTPUT -o $external_if -m state --state ESTABLISHED -p tcp --sport $swtor_ssh_port1 -j ACCEPT
   fi

   if [ -z "$swtor_ssh_port2" ] ; then
       echo [ip-tables : ssh port2 is not used ! ]
   else
      echo [ip-tables : Allow new incomming SSH or even Wireguard Connection / TCP and UDP port 443 on interface eth0 ]
      /usr/sbin/iptables -A INPUT  -i $external_if -m state --state NEW,ESTABLISHED -p tcp --dport $swtor_ssh_port2 -j ACCEPT
      /usr/sbin/iptables -A OUTPUT -o $external_if -m state --state ESTABLISHED -p tcp --sport $swtor_ssh_port2 -j ACCEPT

      # Das UDP Protkoll wird hier nur benötigt sollte auf Port 443 ein weiters Wireguard Interface lauschen !
      # Ansonsten werden keine Verbindung zu Port 443 / UDP zugelassen

      if [ $swtor_allow_wireguard2 = "yes" ] ; then
         /usr/sbin/iptables -A INPUT  -i $external_if -m state --state NEW,ESTABLISHED -p udp --dport $swtor_ssh_port2 -j ACCEPT
         /usr/sbin/iptables -A OUTPUT -o $external_if -m state --state ESTABLISHED -p udp --sport $swtor_ssh_port2 -j ACCEPT
      fi

   fi
fi

if [ $swtor_use_ipsec = "yes" ] ; then
    echo [ip-tables : Allow incomming ESP and IPsec on this host ]
    /usr/sbin/iptables -I INPUT -p esp -j ACCEPT
    /usr/sbin/iptables -I INPUT -m policy --pol ipsec --dir in -j ACCEPT
    /usr/sbin/iptables -I FORWARD -m policy --pol ipsec --dir in -j ACCEPT

    echo [ip-tables : Allow new incomming IKE / UDP port 500 on interface eth0 ]
    /usr/sbin/iptables -A INPUT  -i $external_if -m state --state NEW,ESTABLISHED -p udp --dport 500 -j ACCEPT
    /usr/sbin/iptables -A OUTPUT -o $external_if -m state --state NEW,ESTABLISHED -p udp --dport 500 -j ACCEPT

    echo [ip-tables : Allow new incomming IPSec port 4500 on interface eth0 ]
    /usr/sbin/iptables -A INPUT  -i $external_if -m state --state NEW,ESTABLISHED -p udp --dport 4500 -j ACCEPT
    /usr/sbin/iptables -A OUTPUT -o $external_if -m state --state NEW,ESTABLISHED -p udp --dport 4500 -j ACCEPT

    echo [ip-tables : Allow new incomming IPSec port 1701 on interface eth0 ]
    /usr/sbin/iptables -A INPUT  -i $external_if -m state --state NEW,ESTABLISHED -p udp --dport 1701 -j ACCEPT
    /usr/sbin/iptables -A OUTPUT -o $external_if -m state --state NEW,ESTABLISHED -p udp --dport 1701 -j ACCEPT
else
   echo [ip-tables : No ESP and IPsec rules added on this host ]
fi


if [ $swtor_allow_wireguard1 = "yes" ] ; then
   echo [ip-tables : Allow new incoming Wireguard / UDP port $swtor_wireguard_port1 on interface eth0]
   /usr/sbin/iptables -A INPUT  -i $external_if -m state --state NEW,ESTABLISHED -p udp --dport $swtor_wireguard_port1 -j ACCEPT
   /usr/sbin/iptables -A OUTPUT -o $external_if -m state --state ESTABLISHED -p udp --sport $swtor_wireguard_port1  -j ACCEPT
else
   echo [ip-tables : No wireguard rules added on this host ]
fi

if [ $do_log = "yes" ] ; then
   echo [ip-tables : block all remaing traffic ]

   # Da dieses öffentliche Interface wirklich viel zu viel Traffic generiert, einfach ab in die Wüste

   /usr/sbin/iptables -A INPUT -i eth0  -j DROP

else
  /usr/sbin/iptables -A INPUT -i eth0  -j DROP
fi


if [ $swtor_use_ipsec = "yes" ] ; then
   echo [ip-tables : start ipsec.sh script]
   cd /etc/config/scripts
   killall ipsec.sh > /dev/null 2>&1
   ./ipsec.sh $remote_keep_alive $ipsec_connection &
fi

if [ $using_tor = "yes" ] ; then
   echo [ip-tables : start tor and tornode3ip.sh script]

   systemctl start tor > /dev/null

   echo [ip-tables : tor is now active ]
   cd /etc/config/scripts

   killall tornode3ip.sh > /dev/null 2>&1

   ./tornode3ip.sh > /dev/null 2>&1 &
   echo [ip-tables : tornode3ip.sh ]

fi

if [ $using_snowflake = "yes" ] ; then
   systemctl start snowflake-proxy > /dev/null 2>&1
fi
