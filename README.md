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
   Clients über eine IPSec Verbindung mit dem Netzwerk des Kunden zu verbinden. Der Kunde war sehr zufrieden und er war begeistert wie 
   einfach das neue VPN mittels QR Code auf einem Tablet oder Smartphone einzurichten war.
   Nachdem ich diesen sehre einfach gestrickten Prototypen am laufen hatte, habe ich mich entschlossen selbst ein paar dieser 
   kleinen Server für mich selbst zu nutzen. 

   Was waren meine persönlichen Gründe selbst einen VPN-Server zu betreiben ? 

   1.) Ich liebe meine persönliche digitale Privatsphäre sehr und lasse mich nicht gerne durch einen speicherhungrigen Provider 
       aushorchen der wie zum Bespiel in der Schweiz üblich alle meine Verbindungs-Daten für 6 Monnate speichert.Dass auch die 
       Schweizer Regierung Zugriff auf diese Daten von mir gesammelten Daten erhalten kannn bei Bedarf, macht diese Sache auch nicht 
       leichter.

   2.) Viele Benutzer des Internets denken in gleichen Sphären wie ich und schalten oftmals aus purer Bequemlichkeit einfach eine
       der vielen gratis oder käuflichen VPN zwischen sich und ihrem Provider.Aber genau hier fängt das eigentliche Problem.
       Mein eigener ISP Provider ist beim Rennen um meine persönlichen Verbindunsdaten natürlich disqualifizert, da alle Daten 
       verschlüsselt sind egal um welches VPN es sich schlussendlich handelt (OpenVPN,WireGUard,SSH). 
       Aber der derjenige der mir mein VPN anbietet ... kannn sehr wohl alle meine persönlichen Verbindungen protokollieren.
       Traue ich einem Fremdanbieter von VPN Services der behauptet er würde keine LOG-Dateien über das Verhalten seiner Kunden 
       machen ? Es wurden in den letzten Jahren viele VPN Anbieter hierbei überführt wie sie ihre Kunden ausspähten.
       Den traurigen Negativtekord stellte wohl die Firma Avast auf, welche die zahlendenden VPN Kunden auspionierte und
       diese gesammelten Daten gleich nochmals für Geld weiterverkaufte .....
 
    3.) Bleibt wohl als einzige Alternative nur eine eigener Server zu betreiben, der möglichst von eine paar Leuten benutzt wird
        um die eigenen Verbindungsdaten zu schützten vor der Überwachung des VM-Anbieters der sich auf keinen Fall im gleichen
        Land befinden sollte, wo ich imich selbst befinde.




 




 





   



  

 









 
 



