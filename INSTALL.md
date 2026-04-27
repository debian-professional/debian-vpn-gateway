# debian-vpn-gateway – Installationsanleitung

**Betriebssystem:** Debian 12 Bookworm / 13 Trixie  
**Zielgruppe:** System Engineers mit Linux-Grundkenntnissen  
**Zeitbedarf:** ca. 30–60 Minuten pro Server  

---

## Inhalt

- [Voraussetzungen](#voraussetzungen)
- [VPS beschaffen und vorbereiten](#vps-beschaffen-und-vorbereiten)
- [Basis-Installation Debian](#basis-installation-debian)
- [Repository klonen](#repository-klonen)
- [Symlinks einrichten](#symlinks-einrichten)
- [Standard-Server konfigurieren](#standard-server-konfigurieren)
- [Gateway-Server konfigurieren](#gateway-server-konfigurieren)
- [NordVPN installieren](#nordvpn-installieren)
- [TOR installieren](#tor-installieren)
- [Erster Start und Test](#erster-start-und-test)
- [Troubleshooting](#troubleshooting)

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

> ⚠️ **Konsolenzugriff (KVM/VNC) ist unverzichtbar!**  
> Solltest du dich durch eine fehlerhafte Firewall-Konfiguration aussperren,
> ermöglicht der Konsolenzugriff die Fehlerbehebung direkt am virtuellen
> Bildschirm des Servers. Stelle sicher dass dein Hoster diese Funktion anbietet.

### Wahl des Server-Standorts

Der Server sollte in einem **anderen Land** als dem eigenen Wohnsitz stehen —
idealerweise in einem Land mit strengeren Datenschutzgesetzen und ausserhalb
der eigenen Rechtsprechung.

> ℹ️ Kosten-Nutzen-Tipp: Günstige VPS-Anbieter in Osteuropa bieten oft
> ausgezeichnete Konditionen (~2.50 EUR/Monat für 1 GB RAM, 1 vCPU, 1 Gbit/s)
> bei gleichzeitig guter Datenschutzgesetzgebung.

### Benötigte Software (wird im Verlauf installiert)

**Standard-Server:**
```bash
apt install wireguard wireguard-tools stubby tor proxychains \
            curl sshpass openssh-server git
```

**Gateway-Server (zusätzlich):**
```bash
apt install redsocks
```

---

## VPS beschaffen und vorbereiten

### 1. VPS beim Hoster bestellen

- Debian 12 oder 13 als Betriebssystem wählen
- KVM/VNC-Konsolenzugriff sicherstellen
- Root-Passwort oder SSH-Key beim Bestellvorgang hinterlegen

### 2. Ersten SSH-Login als root durchführen

```bash
ssh root@<DEINE-SERVER-IP>
```

### 3. System aktualisieren

```bash
apt update && apt upgrade -y
```

---

## Basis-Installation Debian

### 1. Benutzer anlegen

Das Framework erwartet einen dedizierten Benutzer `source` der das Repository
verwaltet, sowie einen Benutzer `socks` für SOCKS5-Tunnel-Verbindungen.

```bash
# Benutzer 'source' für Repository-Verwaltung
adduser source

# Benutzer 'socks' für SOCKS5-Tunnel (kein Login-Shell nötig)
adduser --disabled-password --gecos "" socks
```

### 2. SSH-Konfiguration härten

```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

Datei `/etc/ssh/sshd_config` anpassen:

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

> ⚠️ **SSH-Key zwingend einrichten BEVOR `PasswordAuthentication no` gesetzt wird!**
> Sonst sperrst du dich aus.

```bash
# SSH-Key auf dem Server hinterlegen (auf deiner Workstation ausführen)
ssh-copy-id -i ~/.ssh/id_rsa.pub source@<DEINE-SERVER-IP>
ssh-copy-id -i ~/.ssh/id_rsa.pub socks@<DEINE-SERVER-IP>

# SSH-Daemon neu starten
systemctl restart sshd
```

**Verbindungsnachweis via X11 testen:**
```bash
ssh -X source@<DEINE-SERVER-IP> xclock
```
Erscheint die `xclock` auf deinem lokalen Desktop — alles korrekt. 

### 3. IPv6 deaktivieren

IPv6 deaktivieren verhindert potenzielle IP-Leaks über den IPv6-Stack:

```bash
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
```

### 4. Optionale System-Optimierung für 1 GB RAM VPS

Auf Servern mit nur 1 GB RAM empfiehlt es sich das Performance-Tuning Script
auszuführen:

```bash
# Nach dem Klonen des Repositories (siehe nächster Schritt):
cd /home/source/debian-vpn-gateway
bash etc/config/scripts/small.sh
```

Für Server mit 2–4 GB RAM:
```bash
bash etc/config/scripts/big.sh
```

---

## Repository klonen

```bash
# Als Benutzer 'source' einloggen
su - source

# Repository klonen
cd ~
git clone https://github.com/debian-professional/debian-vpn-gateway.git

# Verzeichnis prüfen
ls -la ~/debian-vpn-gateway/
```

---

## Symlinks einrichten

Das Framework verwendet Symlinks um `/etc/config/` mit dem Repository zu
verbinden. Damit wird sichergestellt dass alle Scripts direkt aus dem
Repository geladen werden und ein `git pull` sofort wirksam ist.

```bash
# Als root ausführen
cd /home/source/debian-vpn-gateway
bash etc/config/scripts/directorys.sh
```

Das Script legt folgende Symlinks an:

```
/etc/config/firewall.sh    → ~/debian-vpn-gateway/etc/config/firewall.sh
/etc/config/gateway.sh     → ~/debian-vpn-gateway/etc/config/gateway.sh
/etc/config/random.sh      → ~/debian-vpn-gateway/etc/config/random.sh
/etc/config/scripts/       → ~/debian-vpn-gateway/etc/config/scripts/
/etc/rc.local              → ~/debian-vpn-gateway/etc/rc.local
...
```

**Konfigurationsverzeichnis anlegen:**
```bash
mkdir -p /etc/config/cfg
```

---

## Standard-Server konfigurieren

Ein Standard-Server leitet den Traffic via NordVPN in ein definiertes
Exit-Land und stellt einen SSH SOCKS5-Tunnel bereit.

### 1. Pflichtfelder setzen

```bash
cd /etc/config/cfg

# WAN-IP und Interface-Name
echo '<DEINE-WAN-IP>' > eth0.ip
echo 'enx3'          > eth0.name   # Deinen Interface-Namen anpassen (ip a)
```

### 2. SSH aktivieren

```bash
touch swtor_allow_local_ssh
echo '22'  > swtor_ssh_port1
echo '443' > swtor_ssh_port2
touch swtor_allow_ssh_to_outside
```

### 3. Virtuelles Interface (Dienste-Hub)

```bash
touch virtual_iface
echo '172.29.255.1'  > virtual_iface2
echo '255.255.255.0' > virtual_subnet2
```

### 4. NordVPN konfigurieren

```bash
touch nvpn
echo 'Switzerland'          > nvpn_country   # Zielland anpassen
echo '<DEIN-NORDVPN-TOKEN>' > nvpn_token
chmod 600 nvpn_token
```

> ℹ️ Token erstellen unter my.nordaccount.com → Services → NordVPN → Access Token

### 5. DNS verschlüsseln

```bash
touch stubby
```

### 6. TOR + Noise-Traffic aktivieren (empfohlen)

```bash
touch swtor_tor
echo 'source' > swtor_tor_user
```

### 7. IPv6 deaktivieren

```bash
touch disable_ipv6
```

### Vollständige Konfiguration prüfen

```bash
ls -la /etc/config/cfg/
```

Erwartete Ausgabe:
```
eth0.ip
eth0.name
nvpn
nvpn_country
nvpn_token
swtor_allow_local_ssh
swtor_allow_ssh_to_outside
swtor_ssh_port1
swtor_ssh_port2
stubby
swtor_tor
swtor_tor_user
virtual_iface
virtual_iface2
virtual_subnet2
disable_ipv6
```

---

## Gateway-Server konfigurieren

Ein Gateway-Server leitet den gesamten Traffic von WireGuard-Clients
transparent durch die Standard-Server 1–4.

> ℹ️ Die Basis-Konfiguration (Pflichtfelder, SSH, virtuelles Interface,
> stubby, TOR, IPv6) ist identisch mit dem Standard-Server.
> **NordVPN wird auf dem GW-Server nicht benötigt.**

### 1. Basis-Konfiguration (wie Standard-Server, ohne nvpn)

```bash
cd /etc/config/cfg

echo '<DEINE-WAN-IP>' > eth0.ip
echo 'enx3'          > eth0.name
touch swtor_allow_local_ssh
echo '22'  > swtor_ssh_port1
echo '443' > swtor_ssh_port2
touch swtor_allow_ssh_to_outside
touch virtual_iface
echo '172.29.255.1'  > virtual_iface2
echo '255.255.255.0' > virtual_subnet2
touch stubby
touch swtor_tor
echo 'redirect01'    > swtor_tor_user
touch disable_ipv6
```

### 2. Gateway-Konfigurationsdatei erstellen

Pro Zeile ein Exit-Land und ein Standard-Server:

```bash
cat > /etc/config/cfg/gateway << 'EOF'
redirect01 Germany     172.25.255.2-172.25.255.22 172.29.255.1:1080 172.29.255.1:8080 redirect01@<SERVER1-IP> 172.25.255.1 1080
redirect01 UK          172.26.255.2-172.26.255.22 172.29.255.1:1081 172.29.255.1:8081 redirect01@<SERVER2-IP> 172.26.255.1 1081
redirect01 switzerland 172.27.255.2-172.27.255.22 172.29.255.1:1082 172.29.255.1:8082 redirect01@<SERVER3-IP> 172.27.255.1 1082
redirect01 spain       172.28.255.2-172.28.255.22 172.29.255.1:1083 172.29.255.1:8083 redirect01@<SERVER4-IP> 172.28.255.1 1083
EOF
```

### 3. Gateway-Benutzer setzen

```bash
echo 'redirect01' > /etc/config/cfg/gateway_user
```

### 4. Noise-Traffic Befehle einrichten

```bash
echo 'ssh redirect01@<SERVER1-IP> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' > /etc/config/cfg/gw-host1
echo 'ssh redirect01@<SERVER2-IP> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' > /etc/config/cfg/gw-host2
echo 'ssh redirect01@<SERVER3-IP> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' > /etc/config/cfg/gw-host3
echo 'ssh redirect01@<SERVER4-IP> curl --proxy socks5h://172.29.255.1:9050 https://speedtest.bitel.io/Testdateien/64MB --output /dev/null 2>&1' > /etc/config/cfg/gw-host4
```

### 5. redsocks und proxychains installieren

```bash
apt install redsocks proxychains
```

### 6. redsocks Konfiguration

Die Beispielkonfiguration aus dem Repository verwenden:

```bash
cp /home/source/debian-vpn-gateway/etc/config/sample-config/redsocks/redsocks.conf /etc/redsocks.conf
```

### 7. SSH-Keys zu den Standard-Servern einrichten

Der GW-Server muss sich passwortlos zu allen 4 Standard-Servern verbinden:

```bash
# Als gateway_user (redirect01)
su - redirect01
ssh-keygen -t ed25519 -C "gw-server"

# Public Key auf alle 4 Standard-Server kopieren
ssh-copy-id redirect01@<SERVER1-IP>
ssh-copy-id redirect01@<SERVER2-IP>
ssh-copy-id redirect01@<SERVER3-IP>
ssh-copy-id redirect01@<SERVER4-IP>
```

---

## NordVPN installieren

```bash
cd /etc/config && ./get-nordvpn.sh
```

**NordVPN einrichten:**
```bash
nordvpn login --token <DEIN-TOKEN>
nordvpn set keepalive 60
nordvpn connect <country>
nordvpn status
```

> ℹ️ `nordvpn set keepalive 60` muss **vor** `nordvpn connect` ausgeführt werden.
> Bei aktivem `nvpn`-Schalter erledigt `rc.local` dies automatisch beim Systemstart.

**Verfügbare Länder anzeigen:**
```bash
nordvpn countries
```

> ⚠️ **Bekanntes Problem:** NordVPN setzt beim Start eigene iptables-Regeln.
> Deshalb werden die iptables-Tabellen bei aktivem `nvpn`-Schalter beim
> Scriptstart **nicht** zurückgesetzt. Dies ist normales Verhalten.

---

## TOR installieren

Das Debian Standard-Repository enthält eine veraltete TOR-Version.
TOR direkt vom TOR-Projekt installieren:

```bash
# APT-Quelle hinzufügen
echo "deb [signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] \
  https://deb.torproject.org/torproject.org bookworm main" \
  > /etc/apt/sources.list.d/tor.list

# Signierungsschlüssel installieren
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc \
  | gpg --dearmor | tee /usr/share/keyrings/tor-archive-keyring.gpg >/dev/null

# TOR installieren
apt update
apt install tor deb.torproject.org-keyring

# proxychains installieren
apt install proxychains
```

**TOR-Konfiguration:**
```bash
cp /home/source/debian-vpn-gateway/etc/config/sample-config/tor/torrc /etc/tor/torrc
systemctl restart tor
systemctl status tor
```

---

## Erster Start und Test

### 1. Firewall manuell starten

```bash
cd /etc/config
./firewall.sh
```

Erwartete Ausgabe (Auszug):
```
[ip-tables : allow all traffic on loopback interface 127.0.0.1]
[ip-tables : Allow new incomming SSH / TCP port 22 on interface eth0]
[ip-tables : Allow new incomming SSH or even Wireguard Connection / TCP and UDP port 443]
[ip-tables : nordvpn is active - no iptables flush]
...
```

### 2. Virtuelles Interface prüfen

```bash
ip a show eth0:1
```

Erwartete Ausgabe:
```
eth0:1: <BROADCAST,RUNNING> mtu 1500
    inet 172.29.255.1/24
```

### 3. NordVPN-Status prüfen

```bash
nordvpn status
```

Erwartete Ausgabe:
```
Status: Connected
Country: Switzerland
...
```

### 4. DNS-Verschlüsselung prüfen

```bash
systemctl status stubby
```

Port 53 muss geblockt sein:
```bash
curl --dns-servers 8.8.8.8 https://example.com 2>&1 | grep -i "connect\|refused"
```

### 5. SOCKS5-Tunnel von der Workstation testen

```bash
# Dynamic Port Forward
ssh -p 22 -4C2N -D 127.0.0.1:8080 socks@<DEINE-SERVER-IP>

# IP-Adresse via SOCKS5 prüfen (in separatem Terminal)
curl --proxy socks5h://127.0.0.1:8080 https://ipinfo.io
```

Die angezeigte IP-Adresse muss die NordVPN Exit-IP des gewählten Landes sein.

### 6. Automatischen Start beim Booten einrichten

`rc.local` ist bereits via Symlink eingerichtet. Sicherstellen dass es ausführbar ist:

```bash
chmod +x /etc/rc.local
ls -la /etc/rc.local
```

**System neu starten und prüfen:**
```bash
reboot
```

Nach dem Neustart:
```bash
nordvpn status
systemctl status stubby
systemctl status tor
ip a show eth0:1
```

---

## Updates einspielen

Auf allen Servern:

```bash
cd /home/source/debian-vpn-gateway
git pull
```

Da alle Scripts via Symlinks eingebunden sind, sind die Änderungen sofort
aktiv — ohne Neustart.

---

## Troubleshooting

### SSH-Verbindung nicht möglich

```bash
# Via KVM/VNC-Konsole einloggen und prüfen:
systemctl status sshd
iptables -L INPUT -n | grep 22
```

### NordVPN verbindet sich nicht

```bash
nordvpn logout
nordvpn login --token <TOKEN>
nordvpn set keepalive 60
nordvpn connect <country>
```

### TOR läuft nicht

```bash
systemctl status tor
journalctl -u tor -n 50
```

### Firewall-Regeln zurücksetzen (Notfall)

```bash
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
```

> ⚠️ Nur im Notfall verwenden! Danach sofort `./firewall.sh` ausführen.

### Debug-Modus der Firewall aktivieren

In `firewall.sh` ganz oben:
```bash
fw_debug="yes"
```

Dann alle iptables-Aktionen werden via `syslog` geloggt:
```bash
tail -f /var/log/syslog | grep chain
```

---

*github.com/debian-professional/debian-vpn-gateway*
