Hallo und willkommen :-)

Wieso diese Scriptsammlung überhaupt ? 

Vor etwas mehr als 1 1/2 Jahren hatte ich einen grossen Kunden, der seine alte im Einsatz stehende 
Zywall Firewall unter gar gar keinen Umständen ersetzen wollte. Etwas vorher erschien der 
Android Release V13 welcher keine IPSec Verbindungen über LLT2P mehr unterstützte.
Bei einem Upgrade von Android Version 12 auf Version 13 konnte die alte VPN Konfiguration 
weiter verwendet werden, nicht jedoch bei einem neuen Gerät welches bereits mit Android 
13 ausgeliefert wird. Und so wurde entschieden, die neue Lösung um neue Android Geräte an 
die "alte" USG Firewall zu verbinden, mit so wenig Aufwand wie nur irgendwie möglich zu 
betreiben. Im Klartext es durfte eigentlich fast nichts kosten für den Kunden. 

Die von mir vorgeschlagene Lösung war folgendes : 

- Der Kunde mietet direkt selbst bei einem grossen Anbieter ein kleinen VPS Server unter VMWare.
  Kleine Virtual Private Server (VPS) unter VMWare mit 1GB RAM und 2TB Datenvolumen können 
  heute bereits für weniger als 5 Euro pro Monat betrieben werden. (Das gilt ntürlich nur für 
  andere Länder ausserhalb der Schweiz .... ;-) und in der Schweiz werden für solche VPS mit 
  vergleichbaren Daten rund 20 Franken oder mehr verlangt ) 

- Ich sollte den Server unterhalten und die IPSec Verbindung zur bestehenden Firewall herstellen.

Die allerste rudimentäre Version dieser Scripte lief bereits innerhalb von wenigen Stunden und wurde 
auch durch den Kunden ohne über die Kosten wie üblicherweise zu meckern bezahlt.


   VPN Endgerät 				VMWare-Gateway 				Zywall USG       Netzwerk des Kunden			


   z.B. ein Tablet 
   oder ein Computer 

   1. Das Endgerät erstellt einen 
   Wireguard VPN auf den Gateway Server 
 
   -------------------------------------------->


   Der Gateway Server hat immer eine aktive 
   IPSec Verbindung zur alten Infrastruktur offen
   und alle Wireguard Clients können direkt auf
   das Netzwerk des Kunden zugreifen. 

                                                               --------------------------------------------------->


   Mein rudimentärer Gateway (VmWare) machte eigentlich nichts anders als auf der WirGuardschnittle zu warten und alle 
   Clients über IPSec mit dem Netzwerk des Kunden zu verbinden. Der Kunde war sehr zufrieden und er war begeistert wie 
   einfach das neue VPN mittels QR Code auf einem Tablet oder Smartphone einzurichten war.
 






 
 



