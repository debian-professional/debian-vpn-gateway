# debian-vpn-gateway


Es gibt viele überzeugende Gründe, einen eigenen Linux-Server als VPN 
zu betreiben, anstatt sich auf einen kommerziellen Anbieter zu verlassen. 
Hier ist eine perfekte Einführung, die die wichtigsten Vorteile hervorhebt:

# Warum einen eigenen Linux-Server ?

In einer Zeit, in der Bedenken hinsichtlich Datenschutz und Datensicherheit 
ständig zunehmen, suchen viele nach einfachen alternativen Wegen, ihre 
Online-Privatsphäre zu schützen. Kommerzielle VPN-Anbieter versprechen 
oftmals Anonymität und Sicherheit, doch die Realität sieht oftmals 
anders aus: Du musst darauf vertrauen, dass eine Firma oder eine Privatperson 
(VPN-Anbieter), dessen Geschäftsmodell auf der Verwaltung Deiner 
Daten basiert, Deine Privatsphäre wirklich respektiert und keine Protokolle 
führt oder Deine Informationen an Werbefirmen verkauft. Dies war der 
wahre Grund weshalb Avast in den USA zu einer riesigen Geldstrafe
verurteilt worden ist. Sie haben klammheimlich die VPN-Kundendaten gesammelt 
und ohne Skrupel an Fremdfirmen verkauft.

Die Entscheidung für einen eigenen, selbst gehosteten Linux-VPN-Server 
eliminiert dieses existierende Vertrauensproblem vollständig.

1. Vollständige Kontrolle und Vertrauen: Der grösste Vorteil ist die
absolute Transparenz. Du weisst ganz genau, welche Software auf Deinem
Server läuft, wer darauf Zugriff hat und, am wichtigsten, dass keine 
Verbindungsprotokolle (Logs) erstellt oder gespeichert werden. Es gibt
keine "No-Logs-Richtlinie", der Du blind vertrauen musst, sondern eine
technische Garantie.

2. Keine Datenweitergabe an Dritte: Im Gegensatz zu kommerziellen VPN-Diensten, 
die potenziell gehackt werden, Daten an Werbetreibende verkaufen oder auf 
rechtliche Anordnungen hin kooperieren könnten, bleiben Deine Daten unter 
Deiner direkten Kontrolle. Du und Deine Mitbenutzer des Services sind die 
einzigen Nutzniesser und Du als Administrator der einzige Verantwortliche.

3. Optimierte Leistung und dedizierte Bandbreite: 
Dein VPN ist nicht überfüllt mit Tausenden von anderen Nutzern, die sich
eine Serverkapazität teilen. Du erhältst die volle, dedizierte Bandbreite
Deines gemieteten virtuellen Servers, was zu konsistenteren und oftmals 
schnelleren Verbindungsgeschwindigkeiten führt.

4. Masgeschneiderte Konfiguration: 
Als Betreiber eines eigenen Linux-Servers kannst Du genau die Sicherheitsprotokolle 
(wie WireGuard oder OpenVPN) und andere Einstellungen wählen, die Deinen spezifischen 
Anforderungen entsprechen – ein Grad an Anpassung, den Dir kein kommerzieller Dienst 
anbieten kann.
 
Kurz gesagt: Ein selbst gehostetes VPN bietet maximale Sicherheit durch technische
Souveränität. Es verwandelt das Versprechen der digitalen Privatsphäre in eine
überprüfbare Realität. Während es ein gewisses technisches Grundwissen erfordert,
um es einzurichten und zu administrieren, ist die daraus resultierende Seelenfrieden – 
zu wissen, dass niemand ausser Dir Deine Daten sammelt – unbezahlbar.

## Die Entstehungsgeschichte dieser Scriptsammlung

Die Sammlung dieser Scripte entstand aus einer eher ungewöhnlichen, aber in der
IT-Welt nicht seltenen Situation heraus: Ein ehemaliger Kunde von mir zeigte
eine bemerkenswerte Loyalität gegenüber seiner Hardware. Er weigerte sich vehement,
seine über zwölf Jahre im Einsatz befindliche Firewall vom Typ Zyxel USG 100 
auszutauschen, obwohl diese Firewall längst das Ende ihres natürlichen Lebenszyklus
erreicht hatte und den modernen Sicherheitsanforderungen an einer modernen Firewall
kaum noch genügte. (Eigentlich gar nicht, um ehrlich zu sein.) 

Die eigentliche Herausforderung bestand darin, die Konnektivität und Sicherheit
seines Netzwerks zu gewährleisten, ohne die veraltete, aber vom Kunden geliebte 
"Asbach-Uralt-Version" der Firewall ersetzen zu müssen. Um diese scheinbar
unmögliche Aufgabe zu lösen und moderne VPN-Verbindungen 
(konkret: IKEv2/IPsec und WireGuard) auf der betagten Hardware zu realisieren, 
war ich gezwungen, tief in die Materie einzutauchen und masgeschneiderte Skripte
zu entwickeln, die das System quasi "überlisteten".

Diese Sammlung ist also das direkte Ergebnis dieser kreativen Problemlösung
im Umgang mit veralteter Infrastruktur und dem starken Willen eines Kunden,
an seiner bewährten Technik festzuhalten.

Der Schutz der digitalen Privatsphäre ist ein zentrales Anliegen in der heutigen 
digital vernetzten Welt. Viele Internetnutzer empfinden es als Eingriff in ihre
Grundrechte, wenn ihr Surfverhalten ohne ihre explizite Zustimmung von 
Internetanbietern (ISP), staatlichen Akteuren oder grossen Technologieunternehmen
zu Überwachungs- und Kommerzzwecken analysiert wird. Wenn Du aktiv Massnahmen ergreifen
möchtest, um Deine Online-Identität zu schützen und der ständigen Überwachung zu 
entgehen, findest Du in den folgenden Dokumenten wertvolle Lösungsansätze.


### Was wird alles benötigt ? 

Bevor Du beginnst, die Kontrolle über Deine digitale Privatsphäre
zurückzugewinnen, solltest Du sicherstellen, dass Du die notwendige
Infrastruktur und das erforderliche Wissen auch wirklich mitbringst.
Zunächst benötigst Du den Zugriff auf einen virtuellen privaten Server (VPS),
der das Debian-Betriebssystem in der Version 12 oder 13 unterstützt. Diese Server
sind heutzutage sehr erschwinglich; einfache Instanzen, die für diesen Zweck
vollkommen ausreichen, kosten oft nicht mehr als 5 Euro pro Monat. Darüber hinaus
sind Erfahrungen in der Handhabung der Linux-Kommandozeile unerlässlich. 
Die Einrichtung und Wartung erfordert die Navigation im Terminal, das Bearbeiten
von Konfigurationsdateien und das Ausführen von Befehlen.

### Strategische Wahl des Server-Standorts

Bei der Auswahl des Standorts für Deinen VPN-Server ist der
primäre Sicherheitsgedanke, einen Rechtsraum zu wählen, der nicht Deinem 
eigenen aktuellen Wohnsitz unterliegt und idealerweise strengere Datenschutzgesetze
bietet oder zumindest nicht dem Datenaustausch-Abkommen Deines Heimatlandes
unterliegt.


Für Nutzer aus der Schweiz:

Als Schweizer Bürger ist es ratsam, einen Server im Ausland zu mieten.
Standorte innerhalb der EU, wie beispielsweise Deutschland, sind eine solide Option.
Noch wesentlich vorteilhafter für die Privatsphäre wäre ein Standort ausserhalb der
EU, wie das Vereinigte Königreich (UK), um sich von der EU-Rechtsprechung und den
dortigen Datenvorratsrichtlinien abzugrenzen.


Für Nutzer aus Deutschland:

Deutschen Nutzern wird wirklich dringend empfohlen, den Server nicht direkt in
Deutschland zu hosten. Eine exzellente Alternative wäre die Schweiz, die für ihre
robusten Datenschutzgesetze und ihre Neutralität bekannt ist. Der wirkliche Haken 
dabei: Die Hosting-Preise in der Schweiz können leider das Vier- bis Fünffache der
Kosten für einen vergleichbaren Server in Deutschland betragen.

Allgemeine Empfehlung:

Suche nach einem Standort, der ein gutes Gleichgewicht zwischen starkem
Datenschutzrecht (z.B. Island, Schweiz, oder Länder mit ähnlichen Garantien),
Zuverlässigkeit des Anbieters und erschwinglichen Preisen bietet.



### Übliche und empfohlene Leistungsmerkmale eines VPS

Für den Betrieb eines reinen VPN-Servers benötigst Du keine 
Hochleistungshardware. Die Anforderungen sind relativ gering, 
da der Server hauptsächlich Datenpakete weiterleitet und keine
rechenintensiven Anwendungen hostet. Die folgenden Spezifikationen
sind typisch für einen kosteneffizienten und dennoch leistungsstarken
VPS in der Preisklasse von 3 bis 6 Euro pro Monat:


Technische Mindestanforderungen:

CPU: 
Eine Single-Core-CPU mit mindestens 1.6 GHz ist vollkommen
ausreichend.

Arbeitsspeicher (RAM): 
1 GB RAM ist das Minimum, 2 GB bieten komfortable Reserven
für das Betriebssystem und zusätzliche Dienste.

Festplattenspeicher: 
Eine 20 GB SSD (Solid State Drive) bietet mehr als genügend
Platz für das Betriebssystem Debian und alle notwendigen 
Konfigurationen.


Netzwerk:

1 dedizierte IPv4-Adresse: Unverzichtbar für die Erreichbarkeit
des Servers aus dem Internet.

1 Gbit/s Netzwerkschnittstelle: Stellt sicher, dass die 
physische Verbindung schnell genug ist.

Datenvolumen: 
Ein Inklusiv-Volumen von 2 bis 4 TB pro Monat. Dies reicht in
der Regel für den privaten Gebrauch aus, bei einigen Anbietern
sind mittlerweile auch unlimitierte Tarife üblich.


Wichtige administrative Merkmale:

Konsolenzugriff (KVM/VNC): Ein unverzichtbares Feature. 
Solltest Du Dich durch eine fehlerhafte Firewall-Konfiguration oder
ein Netzwerk-Setup versehentlich via SSH aussperren, ermöglicht der
Konsolenzugriff die Fehlerbehebung direkt am "virtuellen Bildschirm"
des Servers.


---

## Die Firewall – Herzstück der Sicherheitsarchitektur

Das zentrale Element dieser Scriptsammlung ist das Firewall-Script `firewall.sh`.
Es wurde nicht aus vorgefertigten Bausteinen zusammenkopiert, sondern über mehrere
Jahre hinweg in der Praxis entwickelt, getestet und verfeinert. Die nachfolgenden
Abschnitte beschreiben die wichtigsten Sicherheitsmerkmale, die dieses Script
von einer gewöhnlichen iptables-Konfiguration deutlich abheben.


### 1. Früherkennung von ungültigen Paketen in der richtigen Kette

Ein fundamentaler und in der Praxis häufig gemachter Fehler ist die Platzierung
von Paket-Validierungsregeln in der INPUT-Kette. Korrekt und deutlich effizienter
ist die Verwendung der `mangle/PREROUTING`-Kette, da ungültige oder manipulierte
Pakete so abgefangen werden, bevor sie überhaupt in die eigentliche Verarbeitungs-
logik des Kernels gelangen. Dieses Script setzt dieses Prinzip konsequent um.


### 2. Performance-Optimierung durch ESTABLISHED/RELATED-Vorfilter

Bevor die aufwendigen Paket-Validierungsregeln greifen, werden bereits etablierte
und verwandte Verbindungen sofort akzeptiert und aus der weiteren Prüfkette
entlassen. Dies reduziert die CPU-Last erheblich, da der Grossteil des normalen
Netzwerkverkehrs – nämlich bereits bestehende Verbindungen – die 19 nachfolgenden
Prüfregeln gar nicht erst durchlaufen muss.

```
iptables -t mangle -A PREROUTING -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```


### 3. Umfassender Schutz gegen manipulierte TCP-Flags (19 Regeln)

Das Script implementiert 19 präzise Regeln gegen sogenannte "Bogus TCP Flag"-Angriffe.
Diese Angriffsmethoden werden von Port-Scannern wie `nmap` und von gezielten
Reconnaissance-Tools verwendet, um Informationen über das System zu sammeln oder
den TCP/IP-Stack zu destabilisieren. Abgedeckt werden unter anderem:

- **NULL-Scan** (keine Flags gesetzt) – klassische Methode zur stillen Port-Erkundung
- **Xmas-Scan** (FIN, PSH, URG gleichzeitig gesetzt) – erkennt Betriebssystem und offene Ports
- **SYN/FIN-Kombination** – protokollwidrig und eindeutiges Zeichen für Manipulation
- **FIN ohne ACK** – wird von modernen Betriebssystemen nie legitim erzeugt
- **Fragmentierte Pakete** – werden vollständig blockiert
- Weitere 14 spezifische Flag-Kombinationen die kein legitimes Protokoll je erzeugt

Alle diese Regeln sind mit einem `--comment` versehen und können im Debug-Modus
über `fw_debug=yes` einzeln geloggt werden, was die Fehlersuche erheblich vereinfacht.


### 4. SYN-Flood Schutz mit dynamischem Rate-Limiting

Über das `hashlimit`-Modul wird jede Source-IP auf maximal 20 neue SYN-Pakete
pro Sekunde limitiert, mit einer erlaubten Burst-Grösse von 30 Paketen.
Dies schützt effektiv gegen SYN-Flood-Angriffe, bei denen ein Angreifer
durch massenhaftes Senden von TCP-Verbindungsanfragen den Server in die
Knie zu zwingen versucht, ohne dabei legitimen Verkehr zu blockieren.

```
iptables -t mangle -A PREROUTING -p tcp --syn \
  -m hashlimit --hashlimit-above 20/sec --hashlimit-burst 30 \
  --hashlimit-mode srcip --hashlimit-name syn_flood -j DROP
```


### 5. Vollständige ICMP-Kontrolle

Statt ICMP pauschal zu erlauben oder zu verbieten, implementiert das Script
eine granulare Kontrolle aller 30 ICMP-Typen sowohl in der INPUT- als auch
in der OUTPUT-Kette. Erlaubt ist ausschliesslich das, was technisch notwendig
ist – zum Beispiel ICMP-Echo (ping) vom eigenen Server aus. Alle übrigen
ICMP-Typen werden explizit verworfen. Dies verhindert unter anderem:

- ICMP-basierte Reconnaissance (Typ 13 Timestamp, Typ 17 Address Mask)
- ICMP-Redirect-Angriffe (Typ 5)
- Unerwünschte Informationspreisgabe über den Netzwerkpfad


### 6. Vollständige DNS-Leak-Prevention

Ein oft übersehenes Sicherheitsrisiko bei VPN-Servern ist der sogenannte
DNS-Leak: DNS-Anfragen der verbundenen Clients verlassen den Server über
das öffentliche Interface, anstatt durch den gesicherten Tunnel zu laufen.
Das Script verhindert dies auf mehreren Ebenen:

- DNS-Anfragen der WireGuard-Clients werden aktiv auf den konfigurierten
  internen DNS-Server umgeleitet (DNS-Hijacking zum Schutz des Benutzers)
- Alle ausgehenden DNS-Verbindungen über das externe Interface werden
  in der FORWARD-Kette blockiert
- Die Kombination aus `DNAT` und `RETURN`-Regeln stellt sicher, dass
  kein DNS-Paket unkontrolliert den Server verlässt


### 7. Schutz vor IPv6-Leaks

Der gesamte IPv6-Stack wird auf allen Servern bewusst und vollständig
deaktiviert. Dies ist eine kritische Sicherheitsmassnahme: Ein aktiver
aber nicht durch die Firewall abgesicherter IPv6-Stack kann dazu führen,
dass VPN-Tunnel umgangen werden und Verbindungen direkt über IPv6
die echte IP-Adresse des Servers oder des Clients preisgeben.


### 8. Konfigurationsbasierte Architektur – keine hartkodierten Werte

Alle sicherheitsrelevanten Parameter werden ausschliesslich über Dateien
im Verzeichnis `/etc/config/cfg` gesteuert. Ein Feature wird aktiviert,
indem die entsprechende Datei existiert – und deaktiviert, indem sie
gelöscht wird. Dieses Designprinzip hat mehrere Sicherheitsvorteile:

- Keine sensitiven Daten (IP-Adressen, Interface-Namen) im Script selbst
- Einfacher und sicherer Wechsel zwischen Konfigurationen
- Klare Trennung zwischen Logik und Konfiguration
- Durch einen eigenen `custom_rules`-Hook können serverspezifische
  Regeln hinzugefügt werden, ohne das Hauptscript zu verändern


### 9. Strikte Kontrolle des ausgehenden Verkehrs

Anders als in vielen Standard-Konfigurationen, bei denen ausgehender
Verkehr pauschal erlaubt wird, kontrolliert dieses Script auch die
OUTPUT-Kette detailliert. Insbesondere wird sichergestellt, dass:

- Kein DNS-Verkehr (UDP/TCP Port 53) den Server unkontrolliert verlässt
- Ausgehende ICMP-Pakete auf das technisch notwendige Minimum beschränkt sind
- Die Source-IP bei ausgehenden Paketen stets verifiziert wird


### 10. Vollständiger Debug- und Logging-Modus

Über den Schalter `optimize_memory=no` bzw. `fw_debug=yes` kann jede
einzelne der 19 Bogus-Flag-Regeln sowie alle ICMP-Regeln mit einem
individuellen Log-Prefix aktiviert werden. Dies ermöglicht eine präzise
Fehleranalyse im laufenden Betrieb, ohne das Script neu starten zu müssen.
Auf Servern mit wenig RAM kann das Logging über `optimize_memory` vollständig
deaktiviert werden, ohne die Sicherheitsregeln selbst zu beeinflussen.


### Zusammenfassung

Die nachfolgende Tabelle gibt einen kompakten Überblick über die
implementierten Schutzmechanismen:

| Schutzmechanismus                  | Methode                          | Kette               |
|------------------------------------|----------------------------------|---------------------|
| Bogus TCP-Flag Schutz (19 Regeln)  | mangle/PREROUTING DROP           | PREROUTING          |
| SYN-Flood Schutz                   | hashlimit Rate-Limiting          | PREROUTING          |
| Ungültige Pakete                   | conntrack INVALID DROP           | PREROUTING          |
| Performance-Optimierung            | ESTABLISHED/RELATED Vorfilter    | PREROUTING          |
| Fragmentierte Pakete               | -f DROP                          | PREROUTING          |
| ICMP Vollkontrolle                 | Typen 0-30 explizit geregelt     | INPUT / OUTPUT      |
| DNS-Leak Prevention                | DNAT + FORWARD REJECT            | PREROUTING / FORWARD|
| IPv6-Leak Prevention               | IPv6-Stack vollständig deaktiviert | Systemebene       |
| Ausgehender Verkehr                | OUTPUT-Kette detailliert geregelt | OUTPUT             |
| Konfigurationsarchitektur          | /etc/config/cfg Feature-Flags    | Systemebene         |


---

## Der NordVPN-Modus – Geografische Freiheit und maximale Privatsphäre

Eines der ausgefeiltesten und durchdachtesten Features dieses Frameworks ist die
Integration von NordVPN als geografischen Exit-Node. Dieses Konzept löst gleich
mehrere Probleme auf einmal — und das auf eine Art die kein kommerzieller VPN-Anbieter
alleine leisten kann.


### Das Grundprinzip

Das Framework trennt bewusst zwei Dinge voneinander die bei kommerziellen VPN-Anbietern
zwingend gekoppelt sind: den **physischen Serverstandort** und die **geografische
Identität** des ausgehenden Traffics.

Der VPS steht physisch in einem günstigen Rechenzentrum — zum Beispiel in Deutschland
oder Tschechien. Durch die NordVPN-Integration erscheint der gesamte ausgehende Traffic
jedoch mit einer NordVPN-IP-Adresse aus einem frei wählbaren Land. Für alle
WireGuard-Clients die sich auf diesen Server verbinden ist das vollständig transparent:
Sie surfen scheinbar aus der Schweiz, dem Vereinigten Königreich oder Island heraus —
ganz nach Konfiguration.


### Was der VPS-Betreiber sieht — und was nicht

Dies ist der vielleicht wichtigste Aspekt des gesamten Konzepts.

Der Betreiber des VPS — egal ob in Deutschland, Tschechien oder anderswo — hat
theoretisch die Möglichkeit den Netzwerkverkehr seines Servers zu überwachen.
In der Praxis sieht er jedoch ausschliesslich folgendes:

- **Verschlüsselten WireGuard-Traffic** von den Clients zum Server — Inhalt nicht lesbar
- **Verschlüsselten NordVPN-Traffic** vom Server nach aussen — Inhalt nicht lesbar
- **Verschlüsselte DNS-Anfragen** via Stubby (DNS-over-TLS) — nicht als Klartext lesbar
- **Verschlüsselten SSH-Traffic** für die Socks5-Umleitung — Inhalt nicht lesbar

Was der Betreiber **nicht** sehen kann:

- Welche Webseiten die Clients besuchen
- Welche DNS-Anfragen gestellt werden
- Die echten IP-Adressen der verbundenen Clients
- Den Inhalt irgendeiner Kommunikation

Selbst wenn der VPS-Betreiber verpflichtet würde seinen Traffic herauszugeben —
es gibt schlicht nichts Verwertbares zu übergeben. Alle Datenströme sind
mehrfach verschlüsselt.


### Die vollständige Verschleierungskette

Was dieses Framework von einer einfachen VPN-Lösung unterscheidet ist die
Tiefe der Verschleierung auf mehreren unabhängigen Ebenen:

```
WireGuard-Client
    → WireGuard-Tunnel          (verschlüsselt – Ebene 1)
        → redsocks-Redirector   (lokale Umleitung)
            → SSH-Tunnel        (verschlüsselt, unverdächtig – Ebene 2)
                → Socks5-Server (externes System)
                    → NordVPN   (verschlüsselt – Ebene 3)
                        → Internet
```

Auf jeder Ebene wird die Herkunft weiter verschleiert. Kein einzelner Knoten
in dieser Kette kennt das vollständige Bild:

- Der WireGuard-Client kennt nur den VPS
- Der VPS kennt nur den SSH-Tunnel-Endpunkt
- NordVPN kennt nur den VPS — nicht die eigentlichen Clients
- Die Ziel-Webseite kennt nur die NordVPN-IP


### DNS — die oft vergessene Datenspur

DNS-Anfragen sind in vielen VPN-Lösungen die Achillesferse. Eine unverschlüsselte
DNS-Anfrage verrät was ein Benutzer besuchen möchte — noch bevor die eigentliche
Verbindung aufgebaut wird.

Dieses Framework schliesst diese Lücke auf mehreren Ebenen gleichzeitig:

- **Stubby** verschlüsselt alle DNS-Anfragen via DNS-over-TLS (Port 853)
- **PiHole** filtert Werbe- und Tracking-Domains bevor sie den Server verlassen
- **DNS-Hijacking** in der Firewall stellt sicher dass kein Client am DNS-Server
  vorbei kommunizieren kann — auch nicht versehentlich
- **FORWARD-Blockierung** auf Port 53 verhindert jeden unkontrollierten
  DNS-Abfluss über das externe Interface

Der VPS-Betreiber sieht ausschliesslich verschlüsselten DNS-over-TLS Traffic
auf Port 853 — keine lesbaren Domainnamen, keine verwertbaren Informationen.


### Kostenoptimierung durch intelligente Architektur

Ein weiterer entscheidender Vorteil dieses Konzepts ist wirtschaftlicher Natur.

| Variante | Monatliche Kosten | Geografische Flexibilität |
|----------|-------------------|--------------------------|
| Schweizer VPS direkt | ~15-20 EUR | Fix — ein Land |
| Günstiger VPS + NordVPN | ~7-9 EUR | Beliebig wechselbar |
| Ersparnis | ~8-11 EUR/Monat | Bei mehr Flexibilität |

Statt einen teuren Schweizer VPS zu mieten kombiniert man einen günstigen deutschen
oder tschechischen Server mit einer NordVPN-Lizenz. Das Zielland lässt sich jederzeit
durch Änderung einer einzigen Konfigurationsdatei wechseln — ohne Serverumzug,
ohne Neukonfiguration.

Alle WireGuard-Clients profitieren gleichzeitig davon. Die NordVPN-Kosten verteilen
sich auf alle Benutzer des privaten VPN-Dienstes — was für einen einzelnen Benutzer
als Zusatzkosten erscheint, ist für eine Gruppe ein ausgesprochen günstiges Angebot.


### Warum diese Kombination einzigartig ist

Kein kommerzieller VPN-Anbieter kann dieses Sicherheitsniveau alleine bieten:

- **Eigene WireGuard-Infrastruktur** — volle Kontrolle, keine Logs, keine Datenweitergabe
- **Eigene Firewall** — aktiver Schutz statt passiver Durchleitung
- **NordVPN als Exit-Node** — geografische Flexibilität und zusätzliche Anonymisierung
- **SSH-Tunnel** — Traffic erscheint als gewöhnliche SSH-Verbindung
- **DNS-over-TLS** — selbst DNS-Anfragen hinterlassen keine Spuren

Das Beste aus beiden Welten: Die Kontrolle eines selbst betriebenen Servers
kombiniert mit der geografischen Reichweite eines grossen VPN-Anbieters —
zu einem Bruchteil der Kosten einer vergleichbaren kommerziellen Lösung.

> ✅ Der VPS-Betreiber protokolliert ausschliesslich verschlüsselten Traffic.
> Selbst unter Zwang gibt es nichts Verwertbares herauszugeben.


---

---

## Die Standard-Server (Server 1–4) – SOCKS5 über SSH mit Länder-Exit

### Grundprinzip

Das Framework unterstützt den Betrieb von bis zu vier unabhängigen Standard-Servern,
die jeweils in einem Rechenzentrum im Ausland gehostet werden. Jeder Server leitet
seinen gesamten ausgehenden Traffic über NordVPN in ein definiertes Zielland:

| Server | NordVPN Exit-Land | SOCKS5-Port (lokal) |
|--------|-------------------|---------------------|
| Server 1 | Deutschland | 1080 |
| Server 2 | United Kingdom | 1081 |
| Server 3 | Schweiz | 1082 |
| Server 4 | Spanien | 1083 |

Das Zielland wird pro Server über die Konfigurationsdatei `nvpn_country` gesteuert —
ein Wechsel des Exit-Landes erfordert keine Änderung am Script, nur eine neue
Konfigurationsdatei.

### Verbindungsaufbau via SSH Dynamic Port Forwarding

Der Zugriff auf jeden Server erfolgt über einen **SSH SOCKS5-Tunnel** mittels
Dynamic Port Forwarding (`-D`). Der Befehl auf der Client-Seite ist denkbar einfach:

```bash
ssh -D 1080 -N socks@server1.example.com  # Exit: Deutschland
ssh -D 1081 -N socks@server2.example.com  # Exit: UK
ssh -D 1082 -N socks@server3.example.com  # Exit: Schweiz
ssh -D 1083 -N socks@server4.example.com  # Exit: Spanien
```

Der SSH-Client öffnet damit einen lokalen SOCKS5-Proxy-Port. Jede Applikation
die diesen Port als Proxy nutzt, verlässt das Internet über das jeweilige Zielland.

### Vollständige DNS-Sicherheit am SOCKS5-Client

Ein entscheidender Aspekt ist die Verwendung von `socks5h` statt `socks5` im Client:

- **`socks5`** – Hostname-Auflösung passiert **lokal** → DNS-Leak möglich
- **`socks5h`** – Hostname-Auflösung passiert **auf dem Remote-Server** → kein DNS-Leak

```
socks5h://localhost:1080  # Korrekt – DNS auf dem Server, verschlüsselt via Stubby
socks5://localhost:1080   # Falsch  – DNS lokal beim Client, Klartext-Leak
```

Da auf dem Server Port 53 (Klartext-DNS) in der Firewall vollständig geblockt ist
und **Stubby** alle DNS-Anfragen via DNS-over-TLS (Port 853) verschlüsselt,
ist eine unverschlüsselte DNS-Anfrage technisch unmöglich.

### Verbindungsnachweis via X11 Forwarding

Ein einfacher und zuverlässiger Verbindungstest für den Administrator:

```bash
ssh -X admin-user@server1.example.com xclock
```

Erscheint die `xclock` auf dem lokalen Desktop, ist die Verbindung vollständig
funktionsfähig. Die `xclock` lügt nicht — entweder sie erscheint oder nicht.
X11 Forwarding ist deshalb in der `sshd_config` bewusst aktiviert.

### SSH-Serverhärtung

Die `sshd_config` der Standard-Server ist konsequent gehärtet:

```
Port 22
Port 443
PasswordAuthentication no
PermitRootLogin no
AllowUsers admin-user socks
PubkeyAuthentication yes
AddressFamily inet
ListenAddress <WAN-IP>
LogLevel QUIET
```

**Warum Port 443 zusätzlich zu Port 22?**
Viele öffentliche Netzwerke (Hotels, Flughäfen, Unternehmen) blockieren Port 22.
Port 443 ist praktisch überall offen, da er als HTTPS-Port gilt. Der Client
verbindet sich einfach über den verfügbaren Port:

```bash
ssh -D 1080 -N -p 443 socks@server1.example.com  # falls Port 22 geblockt
ssh -D 1080 -N -p 22  socks@server1.example.com  # Standard
```

Der dedizierte `socks`-User ist ausschliesslich für SOCKS5-Tunnel-Verbindungen
vorgesehen und vom Administrator-Account sauber getrennt.

### TOR als Traffic-Obfuskation

Auf allen Standard-Servern läuft bei aktivem `swtor_tor`-Schalter ein lokaler
TOR-Dienst. Das Script `random.sh` generiert kontinuierlich **künstlichen
Hintergrund-Traffic** via TOR zu zufälligen Webseiten:

```bash
curl --proxy socks5h://172.29.255.1:9050 https://www.boredbutton.com/random
```

**Zweck:** Ein Server der ausschliesslich SSH-Tunnel-Traffic erzeugt, fällt
einem aufmerksamen Netzwerkbeobachter auf. Mit dem Noise-Traffic sieht
das Netzwerkprofil wie gewöhnliches Browsing aus. Der eigentliche
SSH-SOCKS5-Traffic verschwindet im Rauschen — klassisches
**Traffic Analysis Resistance**.

### Was das Rechenzentrum sieht

Aus Sicht des VPS-Betreibers — zum Beispiel in Tschechien — ist der Traffic
vollständig opak:

| Sichtbarer Traffic | Tatsächlicher Inhalt |
|---|---|
| Verschlüsselter SSH Port 22/443 | SOCKS5-Tunnel zum Client |
| Verschlüsselter TOR-Traffic | Noise-Traffic via `random.sh` |
| Verschlüsselter NordVPN-Traffic | Exit in DE / UK / CH / ES |
| DNS-over-TLS Port 853 | Stubby-Anfragen |

Kein einziges Byte ist im Klartext lesbar. Selbst unter Zwang gibt es
nichts Verwertbares herauszugeben.

### Automatische Verbindungsüberwachung

Das Script `controll-part` überwacht die SSH-Verbindungen in einer
Endlosschleife und startet sie bei Ausfall automatisch neu. Dabei werden
die Monitoring-Pings selbst via `proxychains` über TOR gesendet:

```bash
proxychains ssh -p 22 -A42C redirect01@your-own-ddns-name02.ddnsfree.com ping -c 3 www.google.com
```

**Voraussetzungen für `proxychains`:**
- Schalter `swtor_tor` muss aktiv sein (`/etc/config/cfg/swtor_tor`)
- Im Gateway-Modus zusätzlich: Schalter `gateway` muss aktiv sein
- Das Binary `proxychains` muss installiert sein

Eine automatische Prüfung bei Systemstart:

```bash
if [ -f /etc/config/cfg/gateway ] && [ -f /etc/config/cfg/swtor_tor ]; then
    if ! command -v proxychains &>/dev/null; then
        echo "FEHLER: proxychains ist nicht installiert!"
        exit 1
    fi
fi
```

---

## Der Gateway-Modus – Transparenter Proxy für alle Endgeräte

### Das Konzept

Der Gateway-Modus ist die fortgeschrittene Betriebsart des Frameworks.
Ein dedizierter GW-Server fungiert als **transparenter Proxy-Gateway**
für beliebige Client-Geräte — Smartphones, Tablets, Windows-PCs, alles
was WireGuard unterstützt.

Der entscheidende Unterschied zum SOCKS5-Modus:

| SOCKS5-Modus | Gateway-Modus |
|---|---|
| Client muss Proxy konfigurieren | Client konfiguriert **nichts** |
| Nur kompatible Apps profitieren | **Gesamter** Traffic umgeleitet |
| `socks5h` muss bekannt sein | WireGuard einrichten → fertig |
| Technisches Wissen nötig | Für jeden Nutzer geeignet |

### Verbindungsaufbau für den Endnutzer

```
1. WireGuard-App installieren
2. QR-Code scannen oder Config-Datei importieren
3. Fertig — gesamter Traffic läuft durch die Infrastruktur
```

Kein Proxy-Eintrag, kein DNS-Setup, kein technisches Wissen erforderlich.

### Die vollständige Kette im Gateway-Modus

```
Client-Gerät (keine Konfiguration nötig)
    → WireGuard (verschlüsselt – Ebene 1)
        → GW-Server
            → redsocks (transparent TCP → SOCKS5)
                → SSH-Tunnel via proxychains/TOR (verschlüsselt – Ebene 2)
                    → Standard-Server 1-4
                        → NordVPN (verschlüsselt – Ebene 3)
                            → Zielland (DE / UK / CH / ES)
```

Auf jeder Ebene wird die Herkunft weiter verschleiert. Kein einzelner
Knoten kennt das vollständige Bild.

### Die Gateway-Konfigurationsdatei

Die Datei `/etc/config/cfg/gateway` steuert den gesamten Gateway-Modus.
Pro Zeile wird ein Client-Netzwerk mit eigenem Exit-Land konfiguriert:

```
redirect01 Germany     172.25.255.2-172.25.255.22  172.29.255.1:1080  172.29.255.1:8080  redirect01@server1  172.25.255.1  1080
redirect01 UK          172.26.255.2-172.26.255.22  172.29.255.1:1081  172.29.255.1:8081  redirect01@server2  172.26.255.1  1081
redirect01 switzerland 172.27.255.2-172.27.255.22  172.29.255.1:1082  172.29.255.1:8082  redirect01@server3  172.27.255.1  1082
redirect01 spain       172.28.255.2-172.28.255.22  172.29.255.1:1083  172.29.255.1:8083  redirect01@server4  172.28.255.1  1083
```

Pro Zeile / pro Exit-Land wird automatisch ein eigenes **WireGuard-Interface**
gestartet. Clients wählen ihr Exit-Land durch die Wahl des WireGuard-Profils.

### Transparente Umleitung via redsocks

`redsocks` leitet den gesamten TCP-Traffic der WireGuard-Clients transparent
auf den SOCKS5-Port um — ohne dass der Client etwas davon merkt. Umgeleitet
werden alle relevanten Ports:

- HTTP (80), HTTPS (443)
- SMTP (25, 465, 587), IMAP (143, 993), POP3 (110, 995)
- DNS-over-TLS (853)
- SFTP (989, 990)
- Google Play / Chrome / WhatsApp (5222–5230)
- RDP (3389)

Jeder nicht explizit erlaubte Port wird geloggt und geblockt.

### Nutzung für versierte Benutzer

Da der GW-Server die vier SSH-SOCKS5-Verbindungen zu den Standard-Servern
bereits etabliert hat und aktiv überwacht, können versierte Benutzer diese
**direkt nutzen** — ohne eigene SSH-Verbindung aufzubauen:

```
socks5h://localhost:1080  → Deutschland
socks5h://localhost:1081  → UK
socks5h://localhost:1082  → Schweiz
socks5h://localhost:1083  → Spanien
```

Die Verbindungen laufen bereits, werden automatisch überwacht und bei
Ausfall neu gestartet. Der versierte Nutzer profitiert von der bestehenden
Infrastruktur ohne zusätzlichen Aufwand.

### Noise-Traffic im Gateway-Modus

Bei aktivem `gateway`- und `swtor_tor`-Schalter erzeugt `random.sh`
zusätzlich Traffic über die `gw-host1..4` Verbindungen via `proxychains`.
Dies erhöht die Ununterscheidbarkeit des Traffics auf dem GW-Server
weiter — der Betreiber des GW-Rechenzentrums sieht ein ununterscheidbares
Gemisch aus WireGuard-, SSH-, TOR- und normalem HTTPS-Traffic.

---

*github.com/debian-professional/debian-vpn-gateway*



