# debian-vpn-gateway – Konfigurationsdokumentation

## firewall.sh – Vollständige Parameterbeschreibung

**Konfigurationsverzeichnis:** `/etc/config/cfg/`  
**Script:** `/etc/config/firewall.sh`  
**Version:** 0.99b  
**Betriebssystem:** Debian 12 Bookworm / 13 Trixie  

---

## Grundprinzip

Das Firewall-Script verwendet eine **konfigurationsbasierte Architektur**. Alle Parameter werden ausschliesslich über Dateien im Verzeichnis `/etc/config/cfg/` gesteuert.

Es gibt zwei Arten von Parameterdateien:

**1. Schalter-Dateien (Feature-Flags)**  
Die blosse Existenz der Datei aktiviert das Feature. Der Inhalt ist irrelevant.

```bash
touch /etc/config/cfg/pihole       # PiHole aktivieren
rm /etc/config/cfg/pihole          # PiHole deaktivieren
```

**2. Wert-Dateien**  
Die Datei enthält einen konkreten Wert (IP-Adresse, Portnummer, Benutzername etc.).

```bash
echo '194.182.86.53' > /etc/config/cfg/eth0.ip
echo '22'            > /etc/config/cfg/swtor_ssh_port1
```

> ⚠️ **Wichtig:** Alle Dateien müssen **ohne Dateiendung** erstellt werden.  
> Korrekt: `pihole` – Falsch: `pihole.txt` oder `pihole.conf`

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
Die öffentliche IP-Adresse des Servers (WAN-Interface). Diese Adresse wird in zahlreichen iptables-Regeln als Source- und Destination-Adresse verwendet. Bei einer falschen Adresse funktioniert die gesamte Firewall nicht korrekt.

**Beispiel:**
```bash
echo '194.182.86.53' > /etc/config/cfg/eth0.ip
```

**Auswirkung:**  
Wird in allen INPUT/OUTPUT-Regeln als externe IP-Adresse referenziert. Auch für SNAT-Regeln (Masquerading) verwendet.

---

### `eth0.name` – Name des WAN-Interfaces

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Interface-Name |
| **Pflichtfeld** | ❗ Ja |
| **Standard** | Kein Standardwert |

**Beschreibung:**  
Der exakte Name des externen Netzwerkinterfaces. Unter OpenStack kann dieser von `eth0` abweichen und z.B. `enx3`, `ens3` oder `ens192` lauten. Den korrekten Namen ermittelt man mit dem Befehl `ip a`.

**Beispiel:**
```bash
echo 'enx3' > /etc/config/cfg/eth0.name
```

**Auswirkung:**  
Wird in allen iptables-Regeln als Interface-Parameter (`-i` / `-o`) verwendet. Ein falscher Name führt dazu dass keine Regeln greifen.

---

## 2. VPN-Modus

---

### `nvpn` – NordVPN-Modus

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert den NordVPN-Kompatibilitätsmodus. Wenn dieser Schalter gesetzt ist, werden die iptables-Tabellen beim Start des Scripts **nicht** zurückgesetzt. Dies ist notwendig weil NordVPN eigene iptables-Regeln setzt die beim Reset verloren gehen würden. Im nvpn-Modus wird der SSH-Tunnel für den Socks5-Redirector nicht automatisch gestartet.

**Beispiel:**
```bash
touch /etc/config/cfg/nvpn
```

**Auswirkung:**  
Verhindert das Flushen der iptables-Tabellen beim Scriptstart. Die bestehenden NordVPN-Regeln bleiben erhalten.

---

## 3. Speicher-Optimierung

---

### `optimize_memory` – RAM-Sparmode

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Deaktiviert das gesamte Logging der Firewall um RAM zu sparen. Empfohlen für Server mit nur 1 GB RAM. Wenn aktiv werden alle Debug- und Log-Variablen auf `no` gesetzt. Die Sicherheitsregeln selbst bleiben vollständig aktiv – nur die Protokollierung wird deaktiviert.

**Beispiel:**
```bash
touch /etc/config/cfg/optimize_memory
```

**Auswirkung:**  
Setzt `fw_debug=no`, `do_log=no`, `do_log_icmp=no`, `swtor_debug=no`. Reduziert den Speicherverbrauch deutlich auf Servern mit wenig RAM.

---

## 4. SSH-Konfiguration

> ℹ️ Alle SSH-Optionen werden nur ausgewertet wenn der Hauptschalter `swtor_allow_local_ssh` aktiv ist.

---

### `swtor_allow_local_ssh` – SSH aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Empfohlen |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert eingehende SSH-Verbindungen auf dem Server. Ohne diesen Schalter sind keine SSH-Verbindungen möglich und der Server ist nur noch über den Konsolenzugriff (KVM/VNC) erreichbar.

> ⚠️ **Äusserste Vorsicht beim Deaktivieren!**

**Beispiel:**
```bash
touch /etc/config/cfg/swtor_allow_local_ssh
```

**Auswirkung:**  
Aktiviert die Auswertung aller SSH-Parameter. Ohne diesen Schalter werden `swtor_ssh_port1` und `swtor_ssh_port2` ignoriert.

---

### `swtor_ssh_port1` – Primärer SSH-Port

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – TCP-Portnummer |
| **Pflichtfeld** | Ja (wenn SSH aktiv) |
| **Standard** | Kein Standardwert |

**Beschreibung:**  
Der primäre TCP-Port auf dem der SSH-Daemon lauscht. Standardmässig Port 22. Es empfiehlt sich aus Sicherheitsgründen einen nicht-standardmässigen Port zu verwenden um automatisierte Angriffe zu reduzieren.

**Beispiel:**
```bash
echo '22' > /etc/config/cfg/swtor_ssh_port1
```

**Auswirkung:**  
Öffnet den angegebenen TCP-Port in der INPUT- und OUTPUT-Kette für neue und bestehende SSH-Verbindungen.

---

### `swtor_ssh_port2` – Sekundärer SSH-Port

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – TCP-Portnummer |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Ein optionaler zweiter SSH-Port. Häufig wird Port 443 verwendet um SSH-Verbindungen als HTTPS-Traffic zu tarnen und restriktive Firewalls zu umgehen.

> ℹ️ **Hinweis:** Wenn WireGuard2 aktiv ist und ebenfalls auf Port 443 lauscht, wird dieser Port für beide Protokolle geöffnet – TCP für SSH, UDP für WireGuard. Da SSH nur TCP und WireGuard nur UDP verwendet, ist dies problemlos möglich.

**Beispiel:**
```bash
echo '443' > /etc/config/cfg/swtor_ssh_port2
```

**Auswirkung:**  
Öffnet den zweiten TCP-Port für SSH. Falls WireGuard2 aktiv ist, wird der gleiche Port auch für UDP (WireGuard) geöffnet.

---

### `swtor_allow_ssh_to_outside` – Ausgehende SSH-Verbindungen

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Erlaubt ausgehende SSH-Verbindungen von diesem Server zu anderen Systemen (Destination Port 22). Ohne diesen Schalter ist es nicht möglich sich von diesem Server aus per SSH auf andere Server einzuloggen.

**Beispiel:**
```bash
touch /etc/config/cfg/swtor_allow_ssh_to_outside
```

**Auswirkung:**  
Erlaubt ausgehende TCP-Verbindungen auf Destination-Port 22.

---

## 5. Virtuelle Interfaces

> ℹ️ Virtuelle Interfaces werden über eth0 erzeugt (`eth0:0`, `eth0:1`, `eth0:2`) und dienen als IPSec-Endpunkte, Socks5-Server und SSH-Zugangspunkte.

---

### `virtual_iface` – Virtuelle Interfaces aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Hauptschalter für alle virtuellen Interfaces. Muss aktiv sein damit `virtual_iface1`, `virtual_iface2` und `virtual_iface3` ausgewertet werden.

**Beispiel:**
```bash
touch /etc/config/cfg/virtual_iface
```

---

### `virtual_iface1` – Virtuelles Interface eth0:0 (IPSec-Endpunkt)

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – IPv4-Adresse |
| **Pflichtfeld** | Ja (wenn IPSec aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Die IP-Adresse des virtuellen Interfaces `eth0:0`. Dieses Interface wird **ausschliesslich** als lokaler IPSec-Endpunkt verwendet. Alle IPSec-Verbindungen werden über diese Adresse abgewickelt. Ohne dieses Interface kann IPSec nicht betrieben werden.

**Beispiel:**
```bash
echo '10.0.0.1' > /etc/config/cfg/virtual_iface1
```

**Auswirkung:**  
Erstellt das virtuelle Interface `ens192:0`. Wird als IPSec-Endpunkt und SNAT-Quelle für IPSec-Traffic verwendet.

---

### `virtual_subnet1` – Subnetz für Interface eth0:0

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – CIDR-Netzwerkadresse |
| **Pflichtfeld** | Ja (wenn virtual_iface1 aktiv) |
| **Standard** | Nicht gesetzt |

**Beispiel:**
```bash
echo '10.0.0.0/24' > /etc/config/cfg/virtual_subnet1
```

---

### `virtual_iface2` – Virtuelles Interface eth0:1 (Socks5/Dienste-Hub)

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – IPv4-Adresse |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Die IP-Adresse des virtuellen Interfaces `eth0:1`. Dieses Interface stellt mehrere Dienste bereit:
- SSH-Zugang (nicht öffentlich)
- Socks5-Server (Ports 1080–1082)
- redsocks-Redirector (Ports 8080–8082)
- TOR-Proxy (Port 9050, optional)

**Beispiel:**
```bash
echo '172.29.255.1' > /etc/config/cfg/virtual_iface2
```

---

### `virtual_subnet2` – Subnetz für Interface eth0:1

**Beispiel:**
```bash
echo '172.29.255.0/24' > /etc/config/cfg/virtual_subnet2
```

---

### `virtual_iface3` – Virtuelles Interface eth0:2 (Reserve)

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – IPv4-Adresse |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Die IP-Adresse des virtuellen Interfaces `eth0:2`. Zum aktuellen Zeitpunkt noch nicht für einen spezifischen Zweck verwendet – steht als Reserve für zukünftige Erweiterungen zur Verfügung.

**Beispiel:**
```bash
echo '172.29.254.1' > /etc/config/cfg/virtual_iface3
```

---

### `virtual_subnet3` – Subnetz für Interface eth0:2

**Beispiel:**
```bash
echo '172.29.254.0/24' > /etc/config/cfg/virtual_subnet3
```

---

## 6. IPSec / StrongSwan

> ⚠️ **IPSec kann nur aktiviert werden wenn `virtual_iface1` konfiguriert ist.** Andernfalls verweigert das Script den Start mit der Meldung: `RTFM and have a nice day!`

---

### `ipsec` – IPSec aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert die IPSec/StrongSwan-Verbindung. Setzt voraus dass StrongSwan installiert und konfiguriert ist (`/etc/ipsec.conf` und `/etc/ipsec.secrets` vorhanden). Ausserdem muss `virtual_iface1` konfiguriert sein.

**Beispiel:**
```bash
touch /etc/config/cfg/ipsec
```

**Auswirkung:**  
Fügt iptables-Regeln für ESP, IKE (Port 500), NAT-T (Port 4500) und L2TP (Port 1701) hinzu. Startet die IPSec-Verbindung.

---

### `ipsec_remote` – IP des entfernten Netzwerks

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – IPv4-Adresse oder CIDR |
| **Pflichtfeld** | Ja (wenn IPSec aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Die IP-Adresse oder das Netzwerk der entfernten IPSec-Gegenstelle. Wird für Routing-Einträge und Firewall-Regeln verwendet.

**Beispiel:**
```bash
echo '172.17.1.0/24' > /etc/config/cfg/ipsec_remote
```

---

### `ipsec_connection` – Name der IPSec-Verbindung

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Text (Verbindungsname) |
| **Pflichtfeld** | Ja (wenn IPSec aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Der Name der IPSec-Verbindung wie er in `/etc/ipsec.conf` definiert ist.

**Beispiel:**
```bash
echo 'mein-vpn-tunnel' > /etc/config/cfg/ipsec_connection
```

**Auswirkung:**  
Das Script führt `ipsec down <name>` und danach `ipsec up <name>` aus.

---

### `ipsec_keep_alive` – Keep-Alive Intervall

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Zahl (Sekunden) |
| **Pflichtfeld** | Ja (wenn IPSec aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Das Intervall in Sekunden für den Keep-Alive-Mechanismus der IPSec-Verbindung. Ein separates Script (`ipsec.sh`) überwacht die Verbindung und startet sie bei Bedarf neu.

**Beispiel:**
```bash
echo '30' > /etc/config/cfg/ipsec_keep_alive
```

---

## 7. WireGuard

> ℹ️ Es können bis zu 2 WireGuard-Interfaces (`wg0` und `wg1`) gleichzeitig betrieben werden.

---

### `swtor_allow_wireguard1` – WireGuard wg0 aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert das erste WireGuard-Interface `wg0`. Lauscht standardmässig auf UDP-Port 80 und verwaltet den Netzwerkbereich `172.255.31.0/24`.

**Beispiel:**
```bash
touch /etc/config/cfg/swtor_allow_wireguard1
```

**Auswirkung:**  
Startet `wg-quick@wg0` und fügt alle notwendigen iptables-Regeln hinzu.

---

### `swtor_wireguard_port1` – UDP-Port für wg0

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – UDP-Portnummer |
| **Pflichtfeld** | Ja (wenn wg0 aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Der UDP-Port auf dem `wg0` auf eingehende Verbindungen lauscht. Port 80 wird häufig gewählt weil er in vielen restriktiven Netzwerken erlaubt ist. Da WireGuard UDP und HTTP TCP verwendet, kann der gleiche Port für beide Protokolle verwendet werden.

**Beispiel:**
```bash
echo '80' > /etc/config/cfg/swtor_wireguard_port1
```

---

### `wireguard_subnet1` – IP-Netzwerk für wg0

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – CIDR-Netzwerkadresse |
| **Pflichtfeld** | Ja (wenn wg0 aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Das private IP-Netzwerk das WireGuard-Clients auf `wg0` zugewiesen bekommen. Clients erhalten IPs im Bereich `172.31.255.2` bis `172.31.255.20`.

**Beispiel:**
```bash
echo '172.255.31.0/24' > /etc/config/cfg/wireguard_subnet1
```

---

### `wireguard_interface1` – Interface-Name für wg0

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Interface-Name |
| **Pflichtfeld** | Ja (wenn wg0 aktiv) |
| **Standard** | Nicht gesetzt |

**Beispiel:**
```bash
echo 'wg0' > /etc/config/cfg/wireguard_interface1
```

---

### `wireguard_private_routing1` – Privates Routing für wg0

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Wenn aktiv werden WireGuard-Clients auf `wg0` **nicht** als Internet-Gateway verwendet – der Traffic wird nicht nach aussen weitergeleitet. Sinnvoll wenn `wg0` nur für den Zugriff auf interne Ressourcen gedacht ist.

**Beispiel:**
```bash
touch /etc/config/cfg/wireguard_private_routing1
```

---

### WireGuard Interface 2 (wg1)

> ℹ️ `wg1` hat die gleichen Parameter wie `wg0`, jedoch mit der Nummer **2**. Es lauscht standardmässig auf UDP-Port 443.

| Parameter | Beschreibung | Beispiel |
|-----------|-------------|---------|
| `swtor_allow_wireguard2` | wg1 aktivieren | `touch /etc/config/cfg/swtor_allow_wireguard2` |
| `swtor_wireguard_port2` | UDP-Port für wg1 | `echo '443' > /etc/config/cfg/swtor_wireguard_port2` |
| `wireguard_subnet2` | IP-Netzwerk für wg1 | `echo '172.255.30.0/24' > /etc/config/cfg/wireguard_subnet2` |
| `wireguard_interface2` | Interface-Name | `echo 'wg1' > /etc/config/cfg/wireguard_interface2` |
| `wireguard_private_routing2` | Kein Internet via wg1 | `touch /etc/config/cfg/wireguard_private_routing2` |

---

## 8. PiHole DNS-Blocker

---

### `pihole` – PiHole aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert die PiHole-Integration. PiHole läuft auf dem `tun0`-Interface mit der IP `172.29.255.2` und dient als DNS-Resolver mit Werbeblocker für alle WireGuard-Clients. Wenn aktiv wird der DNS-Traffic aller Clients automatisch auf PiHole umgeleitet.

**Beispiel:**
```bash
touch /etc/config/cfg/pihole
```

> ⚠️ **PiHole darf nicht auf `eth0` installiert werden!** Es muss ausschliesslich auf dem `tun0`-Interface betrieben werden. Sonst kommt es zu Konflikten mit `stubby` und `dnsmasq`.

---

## 9. TOR

---

### `swtor_tor` – TOR aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert den TOR-Dienst auf dem Server. TOR lauscht auf Port 9050 und ist über das virtuelle Interface `eth0:1` erreichbar. WireGuard-Clients können TOR für anonymes Surfen verwenden.

**Beispiel:**
```bash
touch /etc/config/cfg/swtor_tor
```

---

### `swtor_tor_user` – TOR Benutzer

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Linux-Benutzername |
| **Pflichtfeld** | Ja (wenn TOR aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Der Linux-Benutzername unter dem der TOR-Dienst läuft. Aus Sicherheitsgründen sollte TOR **nie** als root betrieben werden.

**Beispiel:**
```bash
echo 'source' > /etc/config/cfg/swtor_tor_user
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
Aktiviert den `snowflake-proxy`. Snowflake ist ein TOR-Bridge-Plugin das Menschen in zensierten Ländern den Zugang zum TOR-Netzwerk ermöglicht. Der Proxy benötigt einen grossen UDP-Portbereich (32768–60999) der in der Firewall geöffnet wird.

**Beispiel:**
```bash
touch /etc/config/cfg/swtor_snowflake
```

**Auswirkung:**  
Öffnet den UDP-Portbereich 32768–60999. Startet den `snowflake-proxy` Dienst.

---

## 11. Socks5-Umleitung (redirect01)

> ℹ️ Diese Funktion leitet den gesamten HTTP/HTTPS-Traffic der WireGuard0-Clients über einen externen Socks5-Server um. Nützlich um geografische Sperren zu umgehen (z.B. BBC iPlayer).

---

### `redirect01_wg0` – Socks5-Umleitung aktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert die Umleitung des WireGuard0-Traffics über einen externen Socks5-Server. Erfordert dass `virtual_iface2` und `swtor_allow_wireguard1` aktiv sind. Ausserdem müssen `curl`, `sshpass`, `redsocks` und `killall` installiert sein.

**Beispiel:**
```bash
touch /etc/config/cfg/redirect01_wg0
```

**Auswirkung:**  
Aktiviert NAT-Regeln die HTTP/HTTPS/Mail/DNS-Traffic der wg0-Clients auf den lokalen redsocks-Port umleiten. Folgende Ports werden umgeleitet: 25, 80, 110, 123, 143, 443, 465, 587, 853, 989, 990, 993, 995, 5222, 5228.

---

### `redirect01_port` – Lokaler Socks5-Port

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – IP:Port |
| **Pflichtfeld** | Ja (wenn redirect01 aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Die lokale IP-Adresse und der Port des redsocks-Redirectors. Der redsocks-Dienst empfängt den umgeleiteten Traffic und leitet ihn über den SSH-Tunnel zum externen Socks5-Server weiter.

**Beispiel:**
```bash
echo '127.0.0.1:1081' > /etc/config/cfg/redirect01_port
```

---

### `redirect01_user_socks5` – SSH-Tunnel Benutzer

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – Linux-Benutzername |
| **Pflichtfeld** | Ja (wenn redirect01 aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Der Linux-Benutzername unter dem der SSH-Tunnel zum externen Socks5-Server aufgebaut wird.

**Beispiel:**
```bash
echo 'source' > /etc/config/cfg/redirect01_user_socks5
```

---

### `redirect01_command` – SSH-Tunnel Befehl

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Wert-Datei – SSH-Befehlsargumente |
| **Pflichtfeld** | Ja (wenn redirect01 aktiv) |
| **Standard** | Nicht gesetzt |

**Beschreibung:**  
Die SSH-Befehlsargumente für den Aufbau des Socks5-Tunnels zum externen Server.

**Beispiel:**
```bash
echo 'user@remote-server.com -p 22 -D 1081' > /etc/config/cfg/redirect01_command
```

---

## 12. System-Parameter

---

### `stubby` – Verschlüsselter DNS (DNS-over-TLS)

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert den `stubby` DNS-over-TLS Dienst. Stubby verschlüsselt alle DNS-Anfragen und verhindert so dass der Internetanbieter den Datenverkehr überwachen kann.

> ⚠️ **Wichtig:** Stubby darf **nicht** auf `127.0.0.1:53` gebunden werden – dies führt zu Konflikten mit `dnsmasq`. Korrekte Bindung: `127.0.0.1:5353`

**Beispiel:**
```bash
touch /etc/config/cfg/stubby
```

---

### `disable_ipv6` – IPv6 deaktivieren

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Empfohlen |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Deaktiviert den gesamten IPv6-Stack auf dem Server. **Dringend empfohlen** um IPv6-basierte VPN-Leaks zu verhindern. Wenn IPv6 aktiv aber nicht durch die Firewall geschützt ist, können Verbindungen den VPN-Tunnel umgehen und die echte IP-Adresse preisgeben.

**Beispiel:**
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

**Beschreibung:**  
Deaktiviert ein Netzwerkinterface beim Start des Scripts.

**Beispiel:**
```bash
touch /etc/config/cfg/disable_interface
```

---

### `gateway` – Gateway-Modus

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Schalter-Datei (Feature-Flag) |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht aktiv |

**Beschreibung:**  
Aktiviert den Gateway-Modus. In diesem Modus fungiert der Server als Netzwerk-Gateway für andere Geräte.

> ⚠️ **Achtung:** Dieser Modus kann sehr viel Datenvolumen verbrauchen – bis zu 200 GB pro Tag wurden beobachtet!

**Beispiel:**
```bash
touch /etc/config/cfg/gateway
```

---

### `custom_rules` – Benutzerdefinierte iptables-Regeln

| Eigenschaft | Wert |
|-------------|------|
| **Typ** | Ausführbares Script |
| **Pflichtfeld** | Nein |
| **Standard** | Nicht vorhanden |

**Beschreibung:**  
Ein ausführbares Script das serverspezifische iptables-Regeln enthält. Wird am Ende von `firewall.sh` ausgeführt – nach allen Standard-Regeln aber vor der finalen DROP-Regel. Perfekt für Port-Weiterleitungen und serverspezifische Anpassungen.

**Beispiel:**
```bash
cat > /etc/config/cfg/custom_rules << 'EOF'
#!/bin/bash
/usr/sbin/iptables -A INPUT  -i enx3 -p tcp --dport 443 -j ACCEPT
/usr/sbin/iptables -A OUTPUT -o enx3 -p tcp --sport 443 -j ACCEPT
echo [ip-tables : custom iptables rules executed ]
EOF
chmod +x /etc/config/cfg/custom_rules
```

> ⚠️ **`custom_rules` muss ausführbar sein:** `chmod +x /etc/config/cfg/custom_rules`

---

## 13. Übersicht aller Parameter

| Parameter | Typ | Pflicht | Zweck |
|-----------|-----|---------|-------|
| `eth0.ip` | Wert | ❗ Ja | Öffentliche WAN-IP |
| `eth0.name` | Wert | ❗ Ja | Name des WAN-Interfaces |
| `nvpn` | Schalter | Nein | NordVPN-Kompatibilitätsmodus |
| `optimize_memory` | Schalter | Nein | RAM-Sparmode (kein Logging) |
| `swtor_allow_local_ssh` | Schalter | Empfohlen | SSH eingehend aktivieren |
| `swtor_ssh_port1` | Wert | Bedingt | Primärer SSH-Port |
| `swtor_ssh_port2` | Wert | Nein | Sekundärer SSH-Port |
| `swtor_allow_ssh_to_outside` | Schalter | Nein | Ausgehende SSH erlauben |
| `virtual_iface` | Schalter | Nein | Virtuelle Interfaces aktivieren |
| `virtual_iface1` | Wert | Bedingt | IP von eth0:0 (IPSec) |
| `virtual_subnet1` | Wert | Bedingt | Subnetz von eth0:0 |
| `virtual_iface2` | Wert | Nein | IP von eth0:1 (Socks5/Dienste) |
| `virtual_subnet2` | Wert | Bedingt | Subnetz von eth0:1 |
| `virtual_iface3` | Wert | Nein | IP von eth0:2 (Reserve) |
| `virtual_subnet3` | Wert | Bedingt | Subnetz von eth0:2 |
| `ipsec` | Schalter | Nein | IPSec/StrongSwan aktivieren |
| `ipsec_remote` | Wert | Bedingt | IP des entfernten Netzwerks |
| `ipsec_connection` | Wert | Bedingt | Name der IPSec-Verbindung |
| `ipsec_keep_alive` | Wert | Bedingt | Keep-Alive Intervall (Sek.) |
| `swtor_allow_wireguard1` | Schalter | Nein | WireGuard wg0 aktivieren |
| `swtor_wireguard_port1` | Wert | Bedingt | UDP-Port für wg0 |
| `wireguard_subnet1` | Wert | Bedingt | IP-Netzwerk für wg0 |
| `wireguard_interface1` | Wert | Bedingt | Interface-Name für wg0 |
| `wireguard_private_routing1` | Schalter | Nein | Kein Internet über wg0 |
| `swtor_allow_wireguard2` | Schalter | Nein | WireGuard wg1 aktivieren |
| `swtor_wireguard_port2` | Wert | Bedingt | UDP-Port für wg1 |
| `wireguard_subnet2` | Wert | Bedingt | IP-Netzwerk für wg1 |
| `wireguard_interface2` | Wert | Bedingt | Interface-Name für wg1 |
| `wireguard_private_routing2` | Schalter | Nein | Kein Internet über wg1 |
| `pihole` | Schalter | Nein | PiHole DNS-Blocker aktivieren |
| `swtor_tor` | Schalter | Nein | TOR-Dienst aktivieren |
| `swtor_tor_user` | Wert | Bedingt | Linux-User für TOR |
| `swtor_snowflake` | Schalter | Nein | Snowflake-Proxy aktivieren |
| `redirect01_wg0` | Schalter | Nein | Socks5-Umleitung aktivieren |
| `redirect01_port` | Wert | Bedingt | Lokaler Socks5-Port |
| `redirect01_user_socks5` | Wert | Bedingt | User für SSH-Tunnel |
| `redirect01_command` | Wert | Bedingt | SSH-Tunnel Befehl |
| `stubby` | Schalter | Nein | DNS-over-TLS aktivieren |
| `disable_ipv6` | Schalter | Empfohlen | IPv6 komplett deaktivieren |
| `disable_interface` | Schalter | Nein | Interface deaktivieren |
| `gateway` | Schalter | Nein | Gateway-Modus aktivieren |
| `custom_rules` | Script | Nein | Serverspezifische Regeln |

---

## 14. Minimalbeispiel – Einfacher VPN-Server

Das folgende Beispiel zeigt die Mindestkonfiguration für einen einfachen WireGuard VPN-Server ohne IPSec, TOR oder Socks5:

```bash
# Pflichtfelder
echo '194.182.86.53' > /etc/config/cfg/eth0.ip
echo 'enx3'          > /etc/config/cfg/eth0.name

# SSH aktivieren
touch /etc/config/cfg/swtor_allow_local_ssh
echo '22'            > /etc/config/cfg/swtor_ssh_port1

# WireGuard wg0 aktivieren
touch /etc/config/cfg/swtor_allow_wireguard1
echo '51820'         > /etc/config/cfg/swtor_wireguard_port1
echo 'wg0'           > /etc/config/cfg/wireguard_interface1
echo '10.0.0.0/24'   > /etc/config/cfg/wireguard_subnet1

# Sicherheit
touch /etc/config/cfg/disable_ipv6

# Firewall starten
cd /etc/config && ./firewall.sh
```

> ✅ Mit dieser Mindestkonfiguration ist ein funktionsfähiger und sicherer WireGuard VPN-Server betriebsbereit.

---

*github.com/debian-professional/debian-vpn-gateway*

