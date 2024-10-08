Hallo und willkommen :-)

Wieso diese Scriptsammlung überhaupt ? 

Vor etwas mehr als 1 1/2 Jahren hatte ich einen grossen Kunden, der seine alte
im Einsatz stehende Zywall Firewall unter gar gar keinen Umständen ersetzen
wollte. Etwas vorher erschien der Android Release V13 welcher keine IPSec
Verbindungen über LLT2P mehr unterstützte.
Bei einem Upgrade von Android Version 12 auf die Version 13 konnte die zwar die
alte VPN Konfiguration weiter verwendet werden, nicht jedoch bei einem neuen
Gerät welches bereits mit Android 13 ausgeliefert wurdee. 
Und so wurde entschieden, die neue Lösung um neue Android Geräte mit Android 13
an die "alte" USG Firewall zu verbinden, mit so wenig Aufwand wie nur irgendwie
möglich zu ermöglichen. Im Klartext -> 
Es durfte eigentlich fast nichts kosten für den Kunden. 

Die von mir vorgeschlagene Lösung war folgendes : 

- Der Kunde mietet direkt selbst bei einem grossen Anbieter ein kleinen VPS
  Server unter VMWare.Kleine Virtual Private Server (VPS) unter VMWare mit
  1GB RAM und 2TB Datenvolumen können heute bereits für weniger als 5 Euro
  pro Monat betrieben werden. (Das gilt ntürlich nur für Länder ausserhalb 
  der Schweiz .... ;-) und in der Schweiz werden für solche kleinen VPS mit 
  vergleichbaren Daten rund 20 Franken oder mehr verlangt, und diese Kosten
  hätte ich meinem Kunden niemals verkaufen können. 

- Ich sollte den Server unterhalten und im Hintergrund die IPSec Verbindung 
  zur bestehenden USG Firewall herstellen. Die mein etwas schottischer Kunde
  einfach nicht ersetzen wollte.

- Die allerste sehr rudimentäre Version dieser Scripte lief bereits innerhalb
  von wenigen Stunden und wurde auch durch den Kunden ohne Probleme bezahlt.

- Ein vereinfachtes Diagramm zeigt die Verbindungen und ihre Reihenfolge.
  VPN-Endgerät	       VMWare-Gatay	 Zyxel-USG	Netzwerk 

- Das VPN Endgerät erstellt eine Wireguard VPN auf den Gateway Server
  VPN-Emdgerätr ------>VMWare-Getway 

- Der Gateway Server hat immer eine aktive IPSec Verbindung zur alten
  Infrastruktur offen und alle Wireguard Clients können direkt auf
  das Netzwerk des Kunden zugreifen. Hiefür wird zwischen der dem
  Gateway Server und der alten Firewall das IPSec Protokoll verwendet.
  VPN-Emdgerätr ------>VMWare-Getway--->Zyxel-USG------>Netzwerk

- Mein erster rudimentärer Gateway (VmWare) machte eigentlich nichts 
  anders als auf der WirGuardschnittle zu warten und alle Clients über
  eine seperate IPSec Verbindung mit dem Netzwerk des Kunden zu
  verbinden. Der Kunde war sehr zufrieden mit meiner Lösung und er
  war begeistert wie einfach das neue VPN mittels QR Code auf einem
  Tablet oder Smartphone einzurichten war.
  Nachdem ich diesen sehr einfach gestrickten Prototypen am laufen
  hatte, habe ich mich entschlossen selbst ein paar dieser 
  kleinen Server für mich selbst zu nutzen. 

- Was waren meine Gründe selbst einen VPN-Server zu betreiben ? 

- Ich liebe meine persönliche digitale Privatsphäre sehr und lasse
  mich nicht gerne durch einen speicherhungrigen Provider aushorchen
  der wie zum Bespiel in der Schweiz üblich alle meine Verbindungs-Daten 
  für lange 6 Monnate speichert. Gleiches gilt hierbei auch für die 
  Schweizer Regierung welche Zugriff auf diese Daten von mir gesammelten
  Daten erhalten kann bei Bedarf.

- Viele Benutzer des Internets denken in gleichen Sphären wie ich und
  schalten oftmals aus purer Bequemlichkeit einfach eines der vielen gratis
  oder käuflichen VPN's zwischen sich und ihrem Provider.Aber genau hier
  fängt das eigentliche Problem an.Mein eigener ISP Provider ist beim Rennen
  um meine persönlichen Verbindunsdaten natürlich disqualifizert, da alle Daten 
  verschlüsselt sind, egal um welche Art von VPN es sich schlussendlich
  auch handelt (OpenVPN,WireGUard,SSH). 
  Aber derjenige der mir mein VPN anbietet ... kannn sehr wohl alle meine
  persönlichen Verbindungen protokollieren. Traue ich einem Fremdanbieter
  von VPN Services der behauptet er würde keinerlei LOG-Dateien über das
  Verhalten seiner Kunden machen ? Nicht wirklich !!!
  Leider wurden in den letzten Jahren viele VPN Anbieter hierbei überführt
  wie sie trotz einer "NO-LOG" Policy ihre Kunden trotztdem ausspähten.
  Den ganz traurigen Negativtekord stellte hier wohl die Firma Avast auf, 
  welche die zahlendenden VPN Kunden auspionierte und diese gesammelten
  Daten der Kunden gleich nochmals für viel Geld weiterverkaufte .....
 
- Bleibt wohl als einzige echte Alternative wohl nur eine eigener Server
  zu betreiben.


 




 





   



  

 









 
 



