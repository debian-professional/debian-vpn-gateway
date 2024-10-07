Hallo und willkommen :-)

Wieso diese Scriptsammlung überhaupt ? 

Vor etwas mehr als 1 1/2 Jahren hatte ich einen grossen Kunden, der seine alte im Einsatz stehende 
Zywall Firewall unter gar gar keinen Umständen ersetzen wollte. Etwas vorher erschien der 
Android Release V13 welcher keine IPSec Verbindungen über LLT2P mehr unterstützte.
Bei einem Upgrade von Android Version 12 auf Version 13 konnte die alte VPN Konfiguration 
weiter verwendet werden, nicht jedoch bei einem neuen Gerät welches bereits mit Android 
13 ausgeliefert wird. Und so wurde entschieden, die neue Lösung um neue Android Geräte an 
die "alte" USG Firewall zu verbinden, so wenig Aufwand wie möglich zu betreiben. 

Die von mir vorgeschlagene Lösung war folgendes : 

- Der Kunde mietet direkt bei einem grossen Anbieter ein kleinen VPS Server unter VMWare.
- Ich sollte den Server unterhalten und die Verbindung zur bestehenden Firewall herstellen.

Die erste rudimentäre Version dieser Scripte lief bereits innerhalb von wenigen Stunden.

   VPN Endgerät 				VMWare-Gateway 				Zywall USG       Netzwerk des Kunden			


   z.B. ein Tablet 
   oder ein Computer 

   1. Das Endgeeät erstellt einen 
   Wireguard VPN auf den Gateway Server 
 
   -------------------------------------------->


   Der Gateway Server hat immer eine aktive 
   IPSec Verbindung zur alten Infrastruktur offen 

                                                               --------------------------------------------------->


   Mein rudimentärer Gateway (VmWare) machte nichts anders als auf der WirGuardschnittle zu warten und alle Clients über IPSec
   mit dem Netzwerk des Kunden zu verbinden. Der Kunde war zufrieden und er war begeistert wie einfach das neue VPN mittels 
   QR Code auf einem Tablet oder Smartphone einzurichten war. 






 
 



