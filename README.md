# debian-vpn-gateway

> Ein produktionsreifes, konfigurationsbasiertes Privacy-Framework für Debian 12 / 13 —  
> selbst betrieben, vollständig verschlüsselt, ohne Abhängigkeit von kommerziellen VPN-Anbietern.

---

## Inhalt

- [Warum ein eigener Server?](#warum-ein-eigener-server)
- [Architektur](#architektur)
- [Betriebsmodi](#betriebsmodi)
- [Sicherheitsmerkmale der Firewall](#sicherheitsmerkmale-der-firewall)
- [Voraussetzungen](#voraussetzungen)
- [Dokumentation](#dokumentation)
- [Entstehungsgeschichte](#entstehungsgeschichte)

---

## Warum ein eigener Server?

Kommerzielle VPN-Anbieter versprechen Anonymität — verlangen aber blindes Vertrauen in
eine Firma deren Geschäftsmodell auf der Verwaltung deiner Daten basiert. Avast wurde in
den USA zu einer Millionenstrafe verurteilt weil sie VPN-Kundendaten klammheimlich an
Werbenetzwerke verkauft hatten.

Ein selbst betriebener Server eliminiert dieses Vertrauensproblem vollständig:

- **Vollständige Kontrolle** — du weisst genau welche Software läuft und wer Zugriff hat
- **Keine Logs** — technische Garantie statt einer „No-Logs-Policy" der du vertrauen musst
- **Keine Datenweitergabe** — deine Daten bleiben unter deiner direkten Kontrolle
- **Geografische Flexibilität** — Exit-Land jederzeit durch eine Konfigurationszeile wechselbar
- **Kostenoptimierung** — günstiger VPS + NordVPN kostet weniger als ein Schweizer VPS allein

---

## Architektur

### Standard-Server — SOCKS5 über SSH

Jeder Standard-Server leitet den gesamten Traffic über NordVPN in ein definiertes
Exit-Land. Der Client verbindet sich via SSH Dynamic Port Forwarding und erhält
einen lokalen SOCKS5-Proxy-Port.

![Standard-Server Architektur](docs/images/standard-server.svg)

Die vollständige Verschlüsselungskette macht jeden Traffic für den Rechenzentrum-Betreiber
unlesbar: SSH-Tunnel auf Port 22 oder 443, DNS verschlüsselt via Stubby (DNS-over-TLS Port 853),
TOR und Snowflake erzeugen kontinuierlichen Noise-Traffic zur Obfuskation.

### Gateway-Modus — Transparenter Proxy für alle Endgeräte

Der Gateway-Modus macht komplexe Proxy-Konfigurationen für den Endnutzer unsichtbar.
Ein WireGuard-Profil importieren — und der gesamte Traffic läuft automatisch durch
die Infrastruktur, inklusive DNS-Schutz und Exit-Land-Auswahl.

![Gateway-Modus Architektur](docs/images/gateway-modus.svg)

### Drei unabhängige Verschlüsselungsebenen

Die Architektur schichtet drei voneinander unabhängige Verschlüsselungsprotokolle
übereinander. Kein einzelner Knoten in der Kette kennt das vollständige Bild.

![Drei Verschlüsselungsebenen](docs/images/verschluesselung.svg)

---

## Betriebsmodi

### Standard-Server (sample-cfg)

Vier unabhängige Server, jeder mit eigenem NordVPN Exit-Land:

| Server | Exit-Land | SOCKS5-Port lokal |
|--------|-----------|------------------|
| Server 1 | Deutschland | 1080 |
| Server 2 | United Kingdom | 1081 |
| Server 3 | Schweiz | 1082 |
| Server 4 | Spanien | 1083 |

Verbindung vom Client:

```bash
ssh -D 1080 -N socks@server1.example.com        # Port 22
ssh -D 1080 -N -p 443 socks@server1.example.com # falls Port 22 geblockt
```

Im Browser oder System:

```
socks5h://localhost:1080   # → Deutschland (socks5h: DNS-Auflösung remote → kein DNS-Leak)
socks5h://localhost:1081   # → UK
socks5h://localhost:1082   # → Schweiz
socks5h://localhost:1083   # → Spanien
```

> **Wichtig:** `socks5h` (mit `h`) verwenden — nicht `socks5`. Das `h` bedeutet dass die
> Hostname-Auflösung auf dem Remote-Server erfolgt. Mit `socks5` (ohne `h`) passiert DNS
> lokal beim Client → DNS-Leak. Da auf dem Server Port 53 in der Firewall vollständig
> geblockt ist, ist Klartext-DNS technisch unmöglich.

**Verbindungsnachweis via X11:**

```bash
ssh -X admin-user@server1.example.com xclock
```

Erscheint die `xclock` auf dem lokalen Desktop ist die Verbindung vollständig funktionsfähig.

### Gateway-Modus (sample-gw)

Der Gateway-Modus für Endnutzer ohne technisches Vorwissen:

```
1. WireGuard-App installieren (Windows / Linux / Android / iOS)
2. QR-Code scannen oder Config-Datei importieren
3. Fertig — gesamter Traffic läuft durch die Infrastruktur
```

Kein Proxy-Eintrag, kein DNS-Setup, keine Konfiguration auf dem Client-Gerät.
`redsocks` übernimmt die transparente TCP-Umleitung unsichtbar für das Gerät.

Umgeleitete Ports (Auswahl): HTTP (80), HTTPS (443), SMTP (25/465/587),
IMAP (143/993), DNS-over-TLS (853), WhatsApp (5222–5230), RDP (3389).

**Nutzung für versierte Benutzer:** Die vier SSH-SOCKS5-Verbindungen zu den
Standard-Servern sind bereits etabliert und können direkt genutzt werden —
ohne eigene SSH-Verbindung aufzubauen:

```
socks5h://localhost:1080  → Deutschland
socks5h://localhost:1081  → UK
socks5h://localhost:1082  → Schweiz
socks5h://localhost:1083  → Spanien
```

---

## Sicherheitsmerkmale der Firewall

Das Herzstück des Frameworks ist `firewall.sh` — entwickelt, getestet und
über mehrere Jahre in der Praxis verfeinert. Es hebt sich durch folgende
Merkmale von einer Standard-iptables-Konfiguration ab:

### Früherkennung ungültiger Pakete

Paket-Validierungsregeln in der `mangle/PREROUTING`-Kette statt in INPUT —
ungültige Pakete werden abgefangen bevor sie die eigentliche Verarbeitungslogik
des Kernels erreichen.

### 19 Bogus-TCP-Flag-Regeln

Umfassender Schutz gegen Techniken die von Port-Scannern wie `nmap` verwendet
werden: NULL-Scan, Xmas-Scan, SYN/FIN-Kombination, FIN ohne ACK, fragmentierte
Pakete und 14 weitere illegitime Flag-Kombinationen. Alle Regeln sind einzeln
mit `--comment` versehen und können via `fw_debug=yes` geloggt werden.

### SYN-Flood Schutz mit dynamischem Rate-Limiting

```bash
iptables -t mangle -A PREROUTING -p tcp --syn \
  -m hashlimit --hashlimit-above 20/sec --hashlimit-burst 30 \
  --hashlimit-mode srcip --hashlimit-name syn_flood -j DROP
```

Jede Source-IP wird auf maximal 20 neue SYN-Pakete pro Sekunde limitiert,
mit einem Burst von 30 Paketen — effektiver Schutz ohne Blockierung
legitimen Verkehrs.

### Vollständige ICMP-Kontrolle

Granulare Kontrolle aller 30 ICMP-Typen in INPUT und OUTPUT. Erlaubt ist
ausschliesslich was technisch notwendig ist. Verhindert ICMP-basierte
Reconnaissance (Typ 13, Typ 17) und ICMP-Redirect-Angriffe (Typ 5).

### DNS-Leak-Prevention auf mehreren Ebenen

- DNS-Anfragen der WireGuard-Clients werden aktiv auf den internen DNS-Server umgeleitet
- Alle ausgehenden DNS-Verbindungen über das externe Interface werden in FORWARD geblockt
- Stubby verschlüsselt alle DNS-Anfragen via DNS-over-TLS (Port 853)
- Port 53 (Klartext-DNS) ist vollständig geblockt — Klartext-DNS ist technisch unmöglich

### IPv6-Leak-Prevention

Der gesamte IPv6-Stack wird vollständig deaktiviert. Ein aktiver aber nicht
abgesicherter IPv6-Stack kann VPN-Tunnel umgehen und die echte IP-Adresse preisgeben.

### Konfigurationsbasierte Architektur

Alle Parameter werden über Dateien in `/etc/config/cfg/` gesteuert.
Ein Feature wird aktiviert indem die entsprechende Datei existiert —
und deaktiviert indem sie gelöscht wird:

```bash
touch /etc/config/cfg/swtor_tor    # TOR aktivieren
rm    /etc/config/cfg/swtor_tor    # TOR deaktivieren
```

Keine sensitiven Daten im Script selbst. Klare Trennung zwischen Logik
und Konfiguration. Über `custom_rules` können serverspezifische Regeln
hinzugefügt werden ohne das Hauptscript zu verändern.

### Übersicht Schutzmechanismen

| Mechanismus | Methode | Kette |
|---|---|---|
| Bogus TCP-Flags (19 Regeln) | mangle DROP | PREROUTING |
| SYN-Flood Schutz | hashlimit Rate-Limiting | PREROUTING |
| Ungültige Pakete | conntrack INVALID DROP | PREROUTING |
| Performance-Optimierung | ESTABLISHED/RELATED Vorfilter | PREROUTING |
| Fragmentierte Pakete | -f DROP | PREROUTING |
| ICMP-Vollkontrolle | Typen 0–30 explizit geregelt | INPUT / OUTPUT |
| DNS-Leak-Prevention | DNAT + FORWARD REJECT | PREROUTING / FORWARD |
| IPv6-Leak-Prevention | IPv6-Stack deaktiviert | Systemebene |
| Ausgehender Verkehr | OUTPUT-Kette detailliert | OUTPUT |
| Konfigurationsarchitektur | /etc/config/cfg Feature-Flags | Systemebene |

---

## Voraussetzungen

### VPS-Mindestanforderungen

| Ressource | Minimum | Empfohlen |
|-----------|---------|-----------|
| CPU | 1 Core / 1.6 GHz | 2 Cores |
| RAM | 1 GB | 2 GB |
| Storage | 20 GB SSD | 20 GB SSD |
| Netzwerk | 1 Gbit/s | 1 Gbit/s |
| Datenvolumen | 2 TB/Monat | 4 TB/Monat |
| Betriebssystem | Debian 12 | Debian 13 |

> **Wichtig:** Konsolenzugriff (KVM/VNC) ist unverzichtbar. Solltest du dich durch
> eine fehlerhafte Firewall-Konfiguration aussperren, ermöglicht der Konsolenzugriff
> die Fehlerbehebung direkt am virtuellen Bildschirm des Servers.

### Erforderliche Software

**Standard-Server:**
```bash
apt install wireguard wireguard-tools stubby tor proxychains \
            curl sshpass openssh-server
# NordVPN:
cd /etc/config && ./get-nordvpn.sh
```

**Gateway-Server:**
```bash
apt install redsocks proxychains wireguard wireguard-tools \
            stubby tor curl sshpass openssh-server
```

### Strategische Wahl des Server-Standorts

Für maximale Privatsphäre einen Rechtsraum wählen der nicht dem eigenen
Wohnsitzland unterliegt und idealerweise strengere Datenschutzgesetze bietet:

- **Schweizer Nutzer:** Server in Deutschland oder UK (ausserhalb Schweizer Rechtsprechung)
- **Deutsche Nutzer:** Server in der Schweiz, Island oder Tschechien
- **Allgemein:** Tschechien bietet günstige Preise (~2.50 EUR/Monat) und ist
  nicht Mitglied der Five-Eyes-Allianz

### Kosten-Nutzen-Vergleich

| Variante | Monatliche Kosten | Flexibilität |
|----------|------------------|-------------|
| Schweizer VPS direkt | ~15–20 EUR | Fix — ein Land |
| Günstiger VPS + NordVPN | ~7–9 EUR | Beliebig wechselbar |
| 4 VPS + 1 GW-Server (OpenStack) | ~16 EUR | 4 Länder gleichzeitig |

---

## Dokumentation

| Dokument | Inhalt |
|----------|--------|
| [CONFIGURATION.md](CONFIGURATION.md) | Vollständige Parameter-Dokumentation aller cfg-Schalter |
| [INSTALL.md](INSTALL.md) | Schritt-für-Schritt Installationsanleitung |
| [etc/config/sample-cfg/](etc/config/sample-cfg/) | Beispielkonfiguration Standard-Server |
| [etc/config/sample-gw/](etc/config/sample-gw/) | Beispielkonfiguration Gateway-Server |
| [etc/config/sample-config/](etc/config/sample-config/) | Beispiele für sshd_config, stubby, redsocks, proxychains |
| [etc/config/doc/changes](etc/config/doc/changes) | Vollständiges Änderungsprotokoll seit 2024 |

---

## Entstehungsgeschichte

Diese Scriptsammlung entstand aus einer ungewöhnlichen Situation: Ein ehemaliger
Kunde weigerte sich vehement seine über zwölf Jahre im Einsatz befindliche Firewall
(Zyxel USG 100) auszutauschen. Um moderne VPN-Verbindungen (IKEv2/IPsec und WireGuard)
auf der betagten Hardware zu realisieren, war es nötig tief in die Materie einzutauchen
und masgeschneiderte Scripte zu entwickeln.

Was als kreative Problemlösung begann wurde über mehrere Jahre zu einem vollständigen
Privacy-Framework weiterentwickelt — getestet auf realen Servern, verfeinert durch
echte Betriebserfahrung und dokumentiert mit dem Anspruch das beste zu bieten
was als Privatperson technisch möglich ist.

> *Ein selbst gehostetes VPN verwandelt das Versprechen der digitalen Privatsphäre
> in eine überprüfbare Realität.*

---

*github.com/debian-professional/debian-vpn-gateway*
