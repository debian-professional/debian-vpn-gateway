# debian-vpn-gateway – Konfigurationsdokumentation

**Konfigurationsverzeichnis:** `/etc/config/cfg/`  
**Hauptscript:** `/etc/config/firewall.sh`  
**Betriebssystem:** Debian 12 Bookworm / 13 Trixie  
**Projekt:** https://github.com/debian-professional/debian-vpn-gateway  

---

## Grundprinzip

Das Framework verwendet eine **konfigurationsbasierte Architektur**. Alle Parameter
werden ausschliesslich über Dateien im Verzeichnis `/etc/config/cfg/` gesteuert.
Es gibt keine hartkodierten Werte im Code — jede Anpassung erfolgt ausschliesslich
über Konfigurationsdateien.

Es gibt zwei Arten von Parameterdateien:

**1. Schalter-Dateien (Feature-Flags)**  
Die blosse Existenz der Datei aktiviert das Feature. Der Inhalt ist irrelevant.

```bash
touch /etc/config/cfg/swtor_tor      # TOR aktivieren
rm    /etc/config/cfg/swtor_tor      # TOR deaktivieren
```

**2. Wert-Dateien**  
Die Datei enthält einen konkreten Wert (IP-Adresse, Portnummer, Benutzername etc.).

```bash
echo '<DEINE-WAN-IP>' > /etc/config/cfg/eth0.ip
echo '22'            > /etc/config/cfg/swtor_ssh_port1
```

> ⚠️ **Wichtig:** Alle Dateien müssen **ohne Dateiendung** erstellt werden.  
> Korrekt: `pihole` – Falsch: `pihole.txt` oder `pihole.conf`

---

## Betriebsmodi

Das Framework kennt zwei grundlegende Betriebsmodi:

| Modus | Beschreibung | Schlüssel-Schalter |
|-------|-------------|-------------------|
| **Standard-Server** | SSH SOCKS5-Tunnel mit NordVPN Exit-Land | `nvpn` |
| **Gateway-Modus** | Transparenter Proxy-Gateway via WireGuard | `gateway` |

> ⚠️ `nvpn` und `swtor_snowflake` schliessen sich gegenseitig aus.  
> Beide gleichzeitig aktiviert führt zu einem sofortigen Scriptabbruch.

---

## 1. Netzwerk-Grundkonfiguration

> ❗ Diese zwei Parameter sind **zwingend erforderlich**. Ohne sie startet das Script nicht.

---

### `eth0.ip` – Öffentliche IP-Adresse

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – IPv4-Adresse |
| **Pflichtfeld** | ❗ Ja |
| **Standard** | Kein Standardwert |

**Beschreibung:**  
Die öffentliche IP-Adresse des Servers (WAN-Interface). Diese Adresse wird in
zahlreichen iptables-Regeln als Source- und Destination-Adresse verwendet.
Bei einer falschen Adresse funktioniert die gesamte Firewall nicht korrekt.

```bash
echo '<DEINE-WAN-IP>' > /etc/config/cfg/eth0.ip
```

---

### `eth0.name` – Name des WAN-Interfaces

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Interface-Name |
| **Pflichtfeld** | ❗ Ja |
| **Standard** | Kein Standardwert |

**Beschreibung:**  
Der exakte Name des externen Netzwerkinterfaces. Unter OpenStack weicht dieser
häufig von `eth0` ab und lautet z.B. `enx3`, `ens3` oder `ens192`.
Den korrekten Namen ermittelt man mit: `ip a`

```bash
echo 'enx3' > /etc/config/cfg/eth0.name
```

---

### `eth0.dns` – DNS-Server

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – IPv4-Adresse |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht gesetzt |

```bash
echo '9.9.9.9' > /etc/config/cfg/eth0.dns
```

---

## 2. SSH-Konfiguration

> ℹ️ Alle SSH-Optionen werden nur ausgewertet wenn `swtor_allow_local_ssh` aktiv ist.

---

### `swtor_allow_local_ssh` – SSH eingehend aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Empfohlen |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert eingehende SSH-Verbindungen auf dem Server. Ohne diesen Schalter sind
keine SSH-Verbindungen möglich und der Server ist nur noch über den
Konsolenzugriff (KVM/VNC) erreichbar.

> ⚠️ **Äusserste Vorsicht beim Deaktivieren!**

```bash
touch /etc/config/cfg/swtor_allow_local_ssh
```

---

### `swtor_ssh_port1` – Primärer SSH-Port

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – TCP-Portnummer |
| **Pflichtfeld** | Ja (wenn SSH aktiv) |
| **Standard** | Kein Standardwert |

```bash
echo '22' > /etc/config/cfg/swtor_ssh_port1
```

---

### `swtor_ssh_port2` – Sekundärer SSH-Port

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – TCP-Portnummer |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Port 443 wird empfohlen um SSH-Verbindungen als HTTPS-Traffic zu tarnen.
Viele öffentliche Netzwerke (Hotels, Flughäfen, Unternehmen) blockieren Port 22 —
Port 443 ist praktisch überall offen.

Da SSH nur TCP und WireGuard nur UDP als Transportprotokoll verwendet, können
beide problemlos denselben Port nutzen.

> ⚠️ Extrem restriktive Firewalls erkennen SSH-Traffic auf Port 443 und blockieren
> ihn. Alternativen: Port 123 (NTP) oder Port 4500 (IPSec NAT-T).

```bash
echo '443' > /etc/config/cfg/swtor_ssh_port2
```

Entsprechend in der `sshd_config`:
```
Port 22
Port 443
```

---

### `swtor_allow_ssh_to_outside` – Ausgehende SSH-Verbindungen auf TCP Port 22

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Erlaubt ausgehende SSH-Verbindungen zu einem entfernten System auf dem
**TCP Destination Port 22**. Ohne diesen Schalter blockt die iptables-Firewall
alle ausgehenden Verbindungen von diesem Server zu einem Remote-System auf
Port 22 vollständig.

Als Trost kann immerhin zum Loopback-Interface eine Verbindung hergestellt
werden — aber dies dürfte von externer Seite schwer werden, sehr schwer!

> ⚠️ Diese Option sollte wirklich nur mit allergrösster Vorsicht deaktiviert
> werden! Im Gateway-Modus ist dieser Schalter zwingend erforderlich, da der
> GW-Server SSH-Verbindungen zu den Standard-Servern 1–4 auf Port 22 aufbaut.

```bash
touch /etc/config/cfg/swtor_allow_ssh_to_outside
```

---

### Empfohlene SSH-Server Härtung (`sshd_config`)

```
Port 22
Port 443
AddressFamily inet
ListenAddress <DEINE-WAN-IP>
LogLevel QUIET
PermitRootLogin no
AllowUsers admin-user socks
StrictModes yes
AllowTCPForwarding yes
PermitOpen any
MaxSessions 10
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
PrintLastLog no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
```

**Sicherheitsmerkmale im Überblick:**

| Parameter | Zweck |
|-----------|-------|
| `PasswordAuthentication no` | Kein Brute-Force möglich — ausschliesslich Public-Key |
| `PermitRootLogin no` | Root ist direkt nicht angreifbar |
| `AllowUsers admin-user socks` | Nur explizit erlaubte Benutzer können sich einloggen |
| `AddressFamily inet` | Nur IPv4, kein IPv6-Angriffspunkt |
| `X11Forwarding yes` | Für Verbindungsnachweis via `xclock` |

**Zwei dedizierte Benutzer:**
- `admin-user` — Administration und Verbindungsnachweis via X11
- `socks` — ausschliesslich für SOCKS5-Tunnel-Verbindungen der Clients

**Verbindungsnachweis via X11:**
```bash
ssh -X admin-user@server1.example.com xclock
```
Erscheint die `xclock` auf dem lokalen Desktop, ist die Verbindung vollständig
funktionsfähig. Eindeutig und ohne Interpretationsspielraum.

---

## 3. NordVPN-Modus (Standard-Server 1–4)

> ℹ️ Alle drei Parameter `nvpn`, `nvpn_country` und `nvpn_token` müssen gesetzt sein
> damit NordVPN erfolgreich gestartet werden kann.

---

### Konzept

Das Framework trennt bewusst den **physischen Serverstandort** von der
**geografischen Identität** des ausgehenden Traffics. Ein günstiger VPS im
Ausland kombiniert mit NordVPN erscheint nach aussen mit der IP-Adresse des
gewählten Exit-Landes.

> ℹ️ **Wichtig bei der Wahl des Server-Standorts:** Der Server sollte in einem
> anderen Land als dem eigenen Wohnsitz stehen — idealerweise in einem Land mit
> strengeren Datenschutzgesetzen und ausserhalb der eigenen Rechtsprechung.

**Empfohlene Konfiguration für 4 Standard-Server:**

| Server | NordVPN Exit-Land | SOCKS5-Port lokal |
|--------|------------------|------------------|
| Server 1 | Deutschland | 1080 |
| Server 2 | United Kingdom | 1081 |
| Server 3 | Schweiz | 1082 |
| Server 4 | Spanien | 1083 |

**Vollständige Verschlüsselungskette:**
```
Workstation (Linux / Windows / macOS / Android / iOS / ChromeOS)
    → SSH-Tunnel Port 22 oder 443      (verschlüsselt)
        → Standard-Server (VPS im Ausland)
            → DNS  → Stubby (DNS-over-TLS Port 853)
            → Data → NordVPN (keepalive 60) → Zielland
```

**Was der VPS-Betreiber sieht — und was nicht:**

| Sichtbarer Traffic | Tatsächlicher Inhalt |
|---|---|
| Verschlüsselter SSH Port 22 / 443 | SOCKS5-Tunnel zur Workstation |
| Verschlüsselter TOR-Traffic | Noise-Traffic via `random.sh` |
| Verschlüsselter NordVPN-Traffic | Exit DE / UK / CH / ES |
| DNS-over-TLS Port 853 | Stubby-Anfragen |

Kein einziges Byte ist im Klartext lesbar.

---

### SOCKS5-Nutzung auf der Workstation

Eine SSH-Verbindung zum Standard-Server kann von jedem gängigen Betriebssystem
aufgebaut werden — Linux, Windows (PowerShell/PuTTY), macOS, Android, iOS und ChromeOS.

**SSH Dynamic Port Forward (`-D`) — SOCKS5-Proxy lokal:**
```bash
ssh -p 22 -4C2N -D 127.0.0.1:8080 redirect01@server1.example.com  # → Deutschland
ssh -p 22 -4C2N -D 127.0.0.1:8080 redirect01@server2.example.com  # → UK
ssh -p 22 -4C2N -D 127.0.0.1:8080 redirect01@server3.example.com  # → Schweiz
ssh -p 22 -4C2N -D 127.0.0.1:8080 redirect01@server4.example.com  # → Spanien
```

Im Browser oder System:
```
socks5h://127.0.0.1:8080
```

> ⚠️ **Zwingend `socks5h` verwenden, nicht `socks5`!**  
> Das `h` bedeutet: Hostname-Auflösung passiert auf dem **Remote-Server** — kein DNS-Leak.  
> Mit `socks5` (ohne h) passiert die DNS-Auflösung lokal beim Client → DNS-Leak!

Da auf dem Server Port 53 in der Firewall vollständig geblockt ist und Stubby
alle DNS-Anfragen via DNS-over-TLS (Port 853) verschlüsselt, ist eine
unverschlüsselte DNS-Anfrage technisch unmöglich.

---

### Installation von NordVPN

```bash
cd /etc/config && ./get-nordvpn.sh
```

Das Script lädt das offizielle Installationsscript direkt von NordVPN und
richtet automatisch die APT-Paketquelle für zukünftige Updates ein.

```bash
nordvpn --version          # Version prüfen
nordvpn countries          # Verfügbare Länder anzeigen
nordvpn status             # Verbindungsstatus
nordvpn login --token <t>  # Login via Access Token
nordvpn connect <country>  # Verbindung herstellen
nordvpn disconnect         # Verbindung trennen
```

---

### `nvpn` – NordVPN-Modus aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert den NordVPN-Kompatibilitätsmodus. Die iptables-Tabellen werden beim
Scriptstart **nicht** zurückgesetzt, da NordVPN eigene Regeln setzt die beim
Reset verloren gehen würden.

`rc.local` generiert automatisch ein temporäres Script `vpn.sh` das folgende
Schritte in dieser Reihenfolge durchführt:

```bash
nordvpn login --token <token>
nordvpn allowlist add subnet 172.29.255.0/24   # wenn TOR aktiv
nordvpn set dns 127.0.0.1                      # wenn stubby aktiv
nordvpn set keepalive 60                       # Keep-Alive VOR connect setzen
nordvpn connect <country>                      # Verbindung aufbauen
```

> ℹ️ `nordvpn set keepalive 60` muss zwingend **vor** `nordvpn connect` ausgeführt
> werden. Der Wert wird beim Verbindungsaufbau übernommen. Nach dem Connect hat
> die Einstellung keinen Effekt mehr auf die bereits bestehende Verbindung.

```bash
touch /etc/config/cfg/nvpn
```

---

### `nvpn_country` – Zielland für NordVPN

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Ländername (NordVPN-Format) |
| **Pflichtfeld** | Ja (wenn nvpn aktiv) |
| **Standard** | Nicht gesetzt |

```bash
echo 'Switzerland'    > /etc/config/cfg/nvpn_country
echo 'United_Kingdom' > /etc/config/cfg/nvpn_country
echo 'Germany'        > /etc/config/cfg/nvpn_country
echo 'Spain'          > /etc/config/cfg/nvpn_country
```

> ℹ️ Vollständige Länderliste: `nordvpn countries`

---

### `nvpn_token` – Authentifizierungstoken für NordVPN

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – NordVPN Access Token |
| **Pflichtfeld** | Ja (wenn nvpn aktiv) |
| **Standard** | Nicht gesetzt |

Token erstellen unter [my.nordaccount.com](https://my.nordaccount.com) →
*Services → NordVPN → Access Token*

```bash
echo '<DEIN-NORDVPN-TOKEN>' > /etc/config/cfg/nvpn_token
chmod 600 /etc/config/cfg/nvpn_token
```

> ⚠️ Datei muss ausschliesslich für root lesbar sein (`chmod 600`).  
> Der Token darf **niemals** in ein öffentliches Repository eingecheckt werden.

---

## 4. TOR + Noise-Traffic (Traffic Analysis Resistance)

---

### `swtor_tor` – TOR aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert den TOR-Dienst auf Port 9050. Bei aktivem Schalter startet `rc.local`
automatisch `tornode3ip.sh` → `random.sh`.

**Das Script `random.sh` erzeugt massiven Noise-Traffic in einer Endlosschleife:**

**Phase 1 — Link-Generierung (20 Durchläufe):**
```bash
curl --proxy socks5h://172.29.255.1:9050 https://www.boredbutton.com/random
```
20 zufällige URLs werden gesammelt und in `/tmp/links` gespeichert.

**Phase 2 — Traffic-Generierung (pro URL):**
Für jede gesammelte URL wird zufällig (rvalue 0–10) entschieden:
- Die URL wird via TOR abgerufen (`curl --proxy socks5h://...`)
- Im GW-Modus zusätzlich: 64MB Testdatei-Download via `proxychains` über TOR
  auf dem jeweiligen Standard-Server

Das ergibt pro Durchlauf:
- 20× `boredbutton.com` via TOR
- Bis zu 20× zufällige Webseiten via TOR
- Im GW-Modus: bis zu 20× 64MB Downloads via proxychains auf den Standard-Servern

**Gesamtbild der Noise-Traffic Quellen:**

| Quelle | Beschreibung |
|--------|-------------|
| `random.sh` | Endlosschleife: 20x URLs sammeln + besuchen + 64MB Downloads |
| TOR | Onion-Routing Traffic, Relay für andere Nutzer |
| Snowflake | TOR-Bridge-Proxy, Relay für zensierte Nutzer (Port 32768–60999) |
| NordVPN | Verschlüsselter Tunnel, keepalive 60 Sekunden |

Für den VPS-Betreiber ist das ein absolut undurchdringliches, kontinuierliches
Rauschen aus verschlüsseltem Traffic — rund um die Uhr, in beide Richtungen,
ohne erkennbares Muster. **Traffic-Analyse ist unmöglich.**

```bash
touch /etc/config/cfg/swtor_tor
```

> ⚠️ `proxychains` muss installiert sein wenn `swtor_tor` aktiv ist:
> ```bash
> apt install proxychains
> ```

**Installation von TOR:**
```bash
echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] \
  https://deb.torproject.org/torproject.org bookworm main" \
  > /etc/apt/sources.list.d/tor.list

wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
  | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

apt install tor deb.torproject.org-keyring
```

> ℹ️ Das Debian-Paket aus dem Standard-Repository nicht verwenden —
> es ist veraltet. Direkt vom TOR-Projekt installieren (siehe oben).

---

### `swtor_tor_user` – TOR Benutzer

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Linux-Benutzername |
| **Pflichtfeld** | Ja (wenn TOR aktiv) |
| **Standard** | Nicht gesetzt |

TOR darf aus Sicherheitsgründen **nie** als root betrieben werden.

```bash
echo 'source' > /etc/config/cfg/swtor_tor_user
```

---

## 5. Gateway-Modus

Der Gateway-Modus verwandelt einen Server in einen **transparenten Proxy-Gateway**.
Clients werden vollautomatisch und ohne jede eigene Konfiguration in das gewünschte
Exit-Land geleitet.

---

### Konzept

**Vergleich der Betriebsmodi:**

| Standard-Server (SSH) | Gateway-Modus |
|---|---|
| Client konfiguriert `socks5h://` im Browser | Client konfiguriert **nichts** |
| Nur kompatible Apps profitieren | **Gesamter** Traffic umgeleitet |
| Technisches Wissen erforderlich | WireGuard importieren → fertig |

**Vollständige Verschlüsselungskette:**
```
Client-Gerät
    → WireGuard                    (verschlüsselt – Ebene 1)
        → GW-Server
            → redsocks             (transparent TCP → SOCKS5)
                → SSH-Tunnel       (verschlüsselt – Ebene 2)
                    → Server 1–4
                        → NordVPN  (verschlüsselt – Ebene 3)
                            → Zielland
```

Kein Knoten in dieser Kette kennt das vollständige Bild.

---

### Drei Nutzungsmöglichkeiten des Gateway-Servers

Der GW-Server bietet **drei völlig unabhängige Nutzungsmöglichkeiten** gleichzeitig.
Da die vier SSH-SOCKS5-Verbindungen zu den Standard-Servern bereits etabliert sind
und aktiv überwacht werden, können sie direkt genutzt werden:

**Option 1 — SSH Local Port Forward (`-L`):**  
Leitet einen lokalen Port direkt auf einen der SOCKS5-Ports des GW-Servers um.
Die Verbindung läuft über den GW-Server zu den bereits bestehenden SOCKS5-Tunneln.

```bash
ssh -p 22 -4C2N -L 127.0.0.1:8080:172.29.255.1:1080 redirect01@gw-server  # → Deutschland
ssh -p 22 -4C2N -L 127.0.0.1:8080:172.29.255.1:1081 redirect01@gw-server  # → UK
ssh -p 22 -4C2N -L 127.0.0.1:8080:172.29.255.1:1082 redirect01@gw-server  # → Schweiz
ssh -p 22 -4C2N -L 127.0.0.1:8080:172.29.255.1:1083 redirect01@gw-server  # → Spanien
```

Im Browser: `socks5h://127.0.0.1:8080`

**Option 2 — SSH Dynamic Port Forward (`-D`):**  
Öffnet einen SOCKS5-Proxy direkt zum GW-Server. Das Exit-Land ist der
physische Standort des GW-Servers selbst.

```bash
ssh -p 22 -4C2N -D 127.0.0.1:8080 redirect01@gw-server
```

Im Browser: `socks5h://127.0.0.1:8080`

**Option 3 — WireGuard (transparent, kein Browser-Setup):**  
Gesamter Traffic wird ohne jede Client-Konfiguration via redsocks auf den
entsprechenden SOCKS5-Port umgeleitet:

```
wg2 → 172.29.255.1:1080 → Deutschland
wg3 → 172.29.255.1:1081 → UK
wg4 → 172.29.255.1:1082 → Schweiz
wg5 → 172.29.255.1:1083 → Spanien
```

Alle Nutzungsmöglichkeiten sind von allen gängigen Betriebssystemen erreichbar:
Linux · Windows · macOS · Android · iOS · ChromeOS

---

### `gateway` – Gateway-Konfigurationsdatei

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – mehrzeilige Konfiguration |
| **Pflichtfeld** | ❗ Ja (im GW-Modus) |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Die Datei `/etc/config/cfg/gateway` steuert den gesamten Gateway-Modus.
Pro Zeile wird ein Client-Netzwerk mit eigenem Exit-Land konfiguriert.
Pro Zeile wird automatisch ein eigenes WireGuard-Interface gestartet
(beginnend bei `wg2`).

**Format:**
```
<user> <land> <ip-range> <socks5-adresse:port> <redsocks-adresse:port> <ssh-user@server> <dns-server> <port-nr>
```

**Beispiel:**
```
redirect01 Germany     172.25.255.2-172.25.255.22  172.29.255.1:1080  172.29.255.1:8080  redirect01@server1  172.25.255.1  1080
redirect01 UK          172.26.255.2-172.26.255.22  172.29.255.1:1081  172.29.255.1:8081  redirect01@server2  172.26.255.1  1081
redirect01 switzerland 172.27.255.2-172.27.255.22  172.29.255.1:1082  172.29.255.1:8082  redirect01@server3  172.27.255.1  1082
redirect01 spain       172.28.255.2-172.28.255.22  172.29.255.1:1083  172.29.255.1:8083  redirect01@server4  172.28.255.1  1083
```

> ⚠️ **Achtung Datenvolumen:** Im Gateway-Modus wurden bis zu 200 GB
> Datenvolumen pro Tag beobachtet wenn Noise-Downloads nicht korrekt
> dimensioniert sind. Testdateigrösse wurde von 512 MB auf 64 MB reduziert.

---

### `gateway_user` – Benutzer für Gateway-Verbindungen

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Linux-Benutzername |
| **Pflichtfeld** | Ja (wenn gateway aktiv) |
| **Standard** | Nicht gesetzt |

```bash
echo 'redirect01' > /etc/config/cfg/gateway_user
```

---

### `gw-host1` bis `gw-host4` – Noise-Traffic Befehle

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Shell-Befehl |
| **Pflichtfeld** | Ja (wenn gateway + swtor_tor aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Diese vier Dateien enthalten jeweils den Befehl der via `proxychains` über
TOR ausgeführt wird. Der Befehl wird via SSH auf dem jeweiligen
Standard-Server ausgeführt und lädt eine Testdatei via TOR herunter
um Noise-Traffic zu erzeugen.

```bash
echo 'ssh redirect01@<SERVER1-IP> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' \
  > /etc/config/cfg/gw-host1
```

> ℹ️ Die `proxychains`-Aufrufe dieser Dateien sind nur aktiv wenn
> **beide** Schalter gesetzt sind: `gateway` **und** `swtor_tor`.

---

### Transparente Port-Umleitung via redsocks

`redsocks` leitet den TCP-Traffic der WireGuard-Clients transparent auf den
SOCKS5-Port um. Folgende Ports werden umgeleitet:

| Dienst | Port(s) |
|--------|---------|
| HTTP | 80 |
| HTTPS | 443 |
| SMTP | 25, 465, 587 |
| POP3 / POP3S | 110, 995 |
| IMAP / IMAPS | 143, 993 |
| DNS-over-TLS | 853 |
| SFTP | 989, 990 |
| Google Play / Chrome | 5222, 5223, 5228, 5229, 5230 |
| Teamviewer | 5938 |
| RDP | 3389 |

Jeder nicht explizit erlaubte Port wird geloggt und geblockt.

**Installation:**
```bash
apt install redsocks proxychains
```

---

## 6. Virtuelle Interfaces

---

### `virtual_iface` – Virtuelle Interfaces aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

Hauptschalter für alle virtuellen Interfaces.

```bash
touch /etc/config/cfg/virtual_iface
```

---

### `virtual_iface2` – Virtuelles Interface eth0:1 (Dienste-Hub)

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – IPv4-Adresse |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Die IP-Adresse des virtuellen Interfaces `eth0:1`. Dieses Interface stellt
alle Proxy-Dienste bereit:

- SSH-Zugang (Port 22 / 443)
- SOCKS5-Server (Ports 1080–1083)
- redsocks-Redirector (Ports 8080–8083)
- TOR-Proxy (Port 9050, wenn `swtor_tor` aktiv)

**Nmap-Scan auf diesem Interface (Beispiel mit allen Diensten aktiv):**
```
22/tcp   open  ssh
443/tcp  open  https
1080/tcp open  socks
1081/tcp open  socks
1082/tcp open  socks
1083/tcp open  socks
8080/tcp open  http-proxy
8081/tcp open  http-proxy
8082/tcp open  http-proxy
8083/tcp open  http-proxy
9050/tcp open  tor-socks
```

```bash
echo '172.29.255.1' > /etc/config/cfg/virtual_iface2
```

---

### `virtual_subnet2` – Subnetz für eth0:1

```bash
echo '255.255.255.0' > /etc/config/cfg/virtual_subnet2
```

---

## 7. WireGuard

> ℹ️ Es können bis zu 2 WireGuard-Interfaces (`wg0` / `wg1`) manuell konfiguriert werden.
> Im Gateway-Modus werden zusätzlich `wg2`, `wg3`, `wg4`, `wg5` automatisch gestartet
> (je nach Anzahl Zeilen in der `gateway`-Konfigurationsdatei, beginnend bei `wg2`).

> ⚠️ **Bekanntes Problem Debian 13 (Changelog 08/12/25):** Die Pakete `wireguard`
> und `wireguard-tools` haben fälschlicherweise den RT-Kernel als Abhängigkeit
> eingetragen. Die Pakete müssen manuell angepasst werden um den RT-Kernel
> zu verhindern.

---

### `swtor_allow_wireguard1` – WireGuard wg0

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

```bash
touch /etc/config/cfg/swtor_allow_wireguard1
echo '80'              > /etc/config/cfg/swtor_wireguard_port1
echo 'wg0'             > /etc/config/cfg/wireguard_interface1
echo '172.255.31.0/24' > /etc/config/cfg/wireguard_subnet1
```

> ℹ️ Port 80 UDP wird empfohlen — in restriktiven Netzwerken erlaubt.
> Da WireGuard nur UDP und HTTP nur TCP verwendet, können beide Port 80 gleichzeitig nutzen.

---

### `swtor_allow_wireguard2` – WireGuard wg1

```bash
touch /etc/config/cfg/swtor_allow_wireguard2
echo '443'             > /etc/config/cfg/swtor_wireguard_port2
echo 'wg1'             > /etc/config/cfg/wireguard_interface2
echo '172.255.30.0/24' > /etc/config/cfg/wireguard_subnet2
```

---

## 8. IPSec / StrongSwan

> ⚠️ IPSec setzt `virtual_iface1` voraus. Fehlt diese, verweigert das Script
> den Start mit der Meldung: `RTFM and have a nice day!`

---

### `ipsec` – IPSec aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

Fügt iptables-Regeln für ESP, IKE (Port 500), NAT-T (Port 4500) und
L2TP (Port 1701) hinzu.

```bash
touch /etc/config/cfg/ipsec
echo '172.17.1.0/24'   > /etc/config/cfg/ipsec_remote
echo 'mein-vpn-tunnel' > /etc/config/cfg/ipsec_connection
echo '30'              > /etc/config/cfg/ipsec_keep_alive
```

---

## 9. PiHole DNS-Blocker

---

### `pihole` – PiHole aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

> ⚠️ **Kritische Installationshinweise (Changelog 09/03/24):**
> - PiHole darf **keinesfalls** auf dem Hauptinterface `eth0` installiert werden
> - PiHole muss ausschliesslich auf `tun0` betrieben werden
> - Stubby darf **nicht** auf `127.0.0.1:53` gebunden werden — korrekt: `127.0.0.1:5353`
> - Stubby oder dnsmasq im Modus `0.0.0.0` führt zu Konflikten — einer der Dienste fällt aus

```bash
touch /etc/config/cfg/pihole
```

---

## 10. Snowflake-Proxy

---

### `swtor_snowflake` – Snowflake-Proxy aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert den `snowflake-proxy`. Snowflake ermöglicht Menschen in zensierten
Ländern den Zugang zum TOR-Netzwerk. Öffnet den UDP-Portbereich 32768–60999
und erzeugt zusätzlichen Relay-Traffic.

> ⚠️ `nvpn` und `swtor_snowflake` schliessen sich gegenseitig aus!

> ⚠️ **Installationshinweis (Changelog 22/03/24):** Das Debian-Paket ist
> veraltet. Den Proxy aus den Quellen selbst übersetzen oder das aktuelle
> Binary direkt von torproject.org beziehen.
> Aktuelle Version: snowflake-proxy 2.11.0

```bash
touch /etc/config/cfg/swtor_snowflake
```

---

## 11. System-Parameter

---

### `stubby` – Verschlüsselter DNS (DNS-over-TLS)

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Dringend empfohlen |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert den `stubby` DNS-over-TLS Dienst auf Port 853. Da Port 53
(Klartext-DNS) in der Firewall vollständig geblockt ist, ist eine
unverschlüsselte DNS-Anfrage technisch unmöglich.

```bash
touch /etc/config/cfg/stubby
```

---

### `optimize_memory` – RAM-Sparmode

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Deaktiviert das gesamte Logging der Firewall. Empfohlen für Server mit 1 GB RAM.
Die Sicherheitsregeln bleiben vollständig aktiv.

> ⚠️ Bekannte Inkompatibilitäten bei aktivem `optimize_memory` (Changelog 28/10/24):
> - TOR-Dienst
> - PiHole und Webserver

```bash
touch /etc/config/cfg/optimize_memory
```

---

### `disable_ipv6` – IPv6 deaktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Dringend empfohlen |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Deaktiviert den gesamten IPv6-Stack. Ein aktiver aber nicht abgesicherter
IPv6-Stack kann den VPN-Tunnel umgehen und die echte IP-Adresse preisgeben
(Changelog 25/09/24).

```bash
touch /etc/config/cfg/disable_ipv6
```

---

### `disable_interface` – Interface deaktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

```bash
touch /etc/config/cfg/disable_interface
```

---

### `custom_rules` – Benutzerdefinierte iptables-Regeln

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Ausführbares Script |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht vorhanden |

**Beschreibung:**  
Serverspezifische iptables-Regeln die am Ende von `firewall.sh` ausgeführt werden —
nach allen Standard-Regeln aber vor der finalen DROP-Regel.

```bash
cat > /etc/config/cfg/custom_rules << 'EOF'
#!/bin/bash
/usr/sbin/iptables -A INPUT  -i enx3 -p tcp --dport 443 -j ACCEPT
/usr/sbin/iptables -A OUTPUT -o enx3 -p tcp --sport 443 -j ACCEPT
echo [ip-tables : custom iptables rules executed ]
EOF
chmod +x /etc/config/cfg/custom_rules
```

> ⚠️ `custom_rules` muss ausführbar sein: `chmod +x /etc/config/cfg/custom_rules`

---

## 12. Vollständige Parameter-Übersicht

### Standard-Server (sample-cfg)

| Parameter | Typ | Pflicht | Zweck |
|-----------|-----|---------|-------|
| `eth0.ip` | Wert | ❗ Ja | Öffentliche WAN-IP |
| `eth0.name` | Wert | ❗ Ja | Name des WAN-Interfaces |
| `eth0.dns` | Wert | Nein | DNS-Server |
| `nvpn` | Schalter | Nein | NordVPN-Modus aktivieren |
| `nvpn_country` | Wert | Bedingt | Zielland für NordVPN |
| `nvpn_token` | Wert | Bedingt | NordVPN Access Token (chmod 600!) |
| `swtor_allow_local_ssh` | Schalter | Empfohlen | SSH eingehend aktivieren |
| `swtor_ssh_port1` | Wert | Bedingt | Primärer SSH-Port (22) |
| `swtor_ssh_port2` | Wert | Nein | Sekundärer SSH-Port (443) |
| `swtor_allow_ssh_to_outside` | Schalter | Nein | Ausgehende SSH auf TCP Port 22 erlauben |
| `virtual_iface` | Schalter | Nein | Virtuelle Interfaces aktivieren |
| `virtual_iface2` | Wert | Nein | IP von eth0:1 (Dienste-Hub) |
| `virtual_subnet2` | Wert | Bedingt | Subnetz von eth0:1 |
| `swtor_allow_wireguard1` | Schalter | Nein | WireGuard wg0 aktivieren |
| `swtor_wireguard_port1` | Wert | Bedingt | UDP-Port für wg0 |
| `wireguard_subnet1` | Wert | Bedingt | IP-Netzwerk für wg0 |
| `wireguard_interface1` | Wert | Bedingt | Interface-Name wg0 |
| `swtor_allow_wireguard2` | Schalter | Nein | WireGuard wg1 aktivieren |
| `swtor_wireguard_port2` | Wert | Bedingt | UDP-Port für wg1 |
| `wireguard_subnet2` | Wert | Bedingt | IP-Netzwerk für wg1 |
| `wireguard_interface2` | Wert | Bedingt | Interface-Name wg1 |
| `ipsec` | Schalter | Nein | IPSec/StrongSwan aktivieren |
| `ipsec_remote` | Wert | Bedingt | IP des entfernten Netzwerks |
| `ipsec_connection` | Wert | Bedingt | Name der IPSec-Verbindung |
| `ipsec_keep_alive` | Wert | Bedingt | Keep-Alive Intervall (Sek.) |
| `stubby` | Schalter | Empfohlen | DNS-over-TLS aktivieren |
| `swtor_tor` | Schalter | Nein | TOR + Noise-Traffic aktivieren |
| `swtor_tor_user` | Wert | Bedingt | Linux-User für TOR |
| `swtor_snowflake` | Schalter | Nein | Snowflake-Proxy + Noise-Traffic aktivieren |
| `pihole` | Schalter | Nein | PiHole DNS-Blocker aktivieren |
| `optimize_memory` | Schalter | Nein | RAM-Sparmode (kein Logging) |
| `disable_ipv6` | Schalter | Empfohlen | IPv6 komplett deaktivieren |
| `disable_interface` | Schalter | Nein | Interface beim Start deaktivieren |
| `custom_rules` | Script | Nein | Serverspezifische iptables-Regeln |

### Gateway-Modus (sample-gw) – zusätzliche Parameter

| Parameter | Typ | Pflicht | Zweck |
|-----------|-----|---------|-------|
| `gateway` | Wert-Datei | ❗ Ja | Gateway-Konfiguration (pro Zeile ein Exit-Land) |
| `gateway_user` | Wert | ❗ Ja | Linux-User für SSH-Verbindungen zu Server 1–4 |
| `gw-host1` | Wert | Ja | Noise-Befehl via proxychains für Server 1 |
| `gw-host2` | Wert | Ja | Noise-Befehl via proxychains für Server 2 |
| `gw-host3` | Wert | Ja | Noise-Befehl via proxychains für Server 3 |
| `gw-host4` | Wert | Ja | Noise-Befehl via proxychains für Server 4 |

---

## 13. Erforderliche Software

### Standard-Server
```bash
apt install wireguard wireguard-tools stubby tor proxychains \
            curl sshpass openssh-server
cd /etc/config && ./get-nordvpn.sh
```

### Gateway-Server
```bash
apt install redsocks proxychains wireguard wireguard-tools \
            stubby tor curl sshpass openssh-server
```

---

## 14. Minimalbeispiel – Standard-Server Setup

```bash
# Pflichtfelder
echo '<WAN-IP>' > /etc/config/cfg/eth0.ip
echo 'enx3'     > /etc/config/cfg/eth0.name

# SSH (Port 22 + 443)
touch /etc/config/cfg/swtor_allow_local_ssh
echo '22'  > /etc/config/cfg/swtor_ssh_port1
echo '443' > /etc/config/cfg/swtor_ssh_port2
touch /etc/config/cfg/swtor_allow_ssh_to_outside

# NordVPN
touch /etc/config/cfg/nvpn
echo 'Switzerland'  > /etc/config/cfg/nvpn_country
echo '<NVPN-TOKEN>' > /etc/config/cfg/nvpn_token
chmod 600 /etc/config/cfg/nvpn_token

# Dienste-Hub Interface
touch /etc/config/cfg/virtual_iface
echo '172.29.255.1'  > /etc/config/cfg/virtual_iface2
echo '255.255.255.0' > /etc/config/cfg/virtual_subnet2

# DNS verschlüsseln
touch /etc/config/cfg/stubby

# TOR + Noise-Traffic
touch /etc/config/cfg/swtor_tor
echo 'source' > /etc/config/cfg/swtor_tor_user

# Sicherheit
touch /etc/config/cfg/disable_ipv6
```

---

## 15. Minimalbeispiel – Gateway-Server Setup

```bash
# Pflichtfelder (wie Standard-Server, ohne nvpn)
echo '<WAN-IP>' > /etc/config/cfg/eth0.ip
echo 'enx3'     > /etc/config/cfg/eth0.name
touch /etc/config/cfg/swtor_allow_local_ssh
echo '22'  > /etc/config/cfg/swtor_ssh_port1
echo '443' > /etc/config/cfg/swtor_ssh_port2
touch /etc/config/cfg/swtor_allow_ssh_to_outside
touch /etc/config/cfg/virtual_iface
echo '172.29.255.1'  > /etc/config/cfg/virtual_iface2
echo '255.255.255.0' > /etc/config/cfg/virtual_subnet2
touch /etc/config/cfg/stubby
touch /etc/config/cfg/swtor_tor
echo 'redirect01' > /etc/config/cfg/swtor_tor_user
touch /etc/config/cfg/disable_ipv6

# Gateway-Konfiguration
cat > /etc/config/cfg/gateway << 'EOF'
redirect01 Germany     172.25.255.2-172.25.255.22 172.29.255.1:1080 172.29.255.1:8080 redirect01@<SERVER1> 172.25.255.1 1080
redirect01 UK          172.26.255.2-172.26.255.22 172.29.255.1:1081 172.29.255.1:8081 redirect01@<SERVER2> 172.26.255.1 1081
redirect01 switzerland 172.27.255.2-172.27.255.22 172.29.255.1:1082 172.29.255.1:8082 redirect01@<SERVER3> 172.27.255.1 1082
redirect01 spain       172.28.255.2-172.28.255.22 172.29.255.1:1083 172.29.255.1:8083 redirect01@<SERVER4> 172.28.255.1 1083
EOF

echo 'redirect01' > /etc/config/cfg/gateway_user

# Noise-Traffic Befehle
echo 'ssh redirect01@<SERVER1> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' > /etc/config/cfg/gw-host1
echo 'ssh redirect01@<SERVER2> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' > /etc/config/cfg/gw-host2
echo 'ssh redirect01@<SERVER3> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' > /etc/config/cfg/gw-host3
echo 'ssh redirect01@<SERVER4> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' > /etc/config/cfg/gw-host4
```

---

*github.com/debian-professional/debian-vpn-gateway*
