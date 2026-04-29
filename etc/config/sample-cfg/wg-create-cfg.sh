#!/bin/bash

# =============================================================================
# wg-create-cfg.sh - WireGuard Konfiguration erstellen
# =============================================================================
# Ablageort : /etc/config/scripts/wg-create-cfg.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-create-cfg.sh
# Aufgabe   : Erstellt eine vollständige WireGuard Konfiguration für wg0 und wg1
#             mit je 20 Clients (Schlüssel, Config-Dateien, QR-Codes)
#             Zielverzeichnis: /etc/config/cfg/wireguard/
# =============================================================================

# Root-Check
if [[ $EUID -ne 0 ]]; then
    echo "FEHLER: Dieses Script muss als root ausgeführt werden!"
    exit 1
fi

# Prüfen ob WireGuard installiert ist
if ! command -v wg &>/dev/null; then
    echo "FEHLER: WireGuard ist nicht installiert!"
    echo "       Bitte zuerst wg-install.sh ausführen."
    exit 1
fi

# Prüfen ob qrencode installiert ist
if ! command -v qrencode &>/dev/null; then
    echo "FEHLER: qrencode ist nicht installiert!"
    echo "       Bitte zuerst wg-install.sh ausführen."
    exit 1
fi

# Prüfen ob Gateway-Modus aktiv ist
if [ -f /etc/config/cfg/gateway ]; then
    echo "FEHLER: Gateway-Modus ist aktiv!"
    echo "       wg-create-cfg.sh darf nicht auf einem Gateway-Server ausgeführt werden."
    exit 1
fi

# Prüfen ob eth0.dns existiert
if [ ! -f /etc/config/cfg/eth0.dns ]; then
    echo "FEHLER: /etc/config/cfg/eth0.dns nicht gefunden!"
    echo "       Diese Datei wird für den WAN-Hostnamen benötigt."
    exit 1
fi

# WAN-Hostname aus eth0.dns lesen
WAN_DNS=$(cat /etc/config/cfg/eth0.dns | tr -d '[:space:]')
if [ -z "$WAN_DNS" ]; then
    echo "FEHLER: /etc/config/cfg/eth0.dns ist leer!"
    exit 1
fi

echo "[wg-create-cfg] WAN-Hostname: $WAN_DNS"

# Prüfen ob bereits eine Konfiguration existiert
if [ -d /etc/config/cfg/wireguard ] && [ -n "$(ls -A /etc/config/cfg/wireguard 2>/dev/null)" ]; then
    echo "FEHLER: /etc/config/cfg/wireguard/ existiert bereits und ist nicht leer!"
    echo "       Eine bestehende Konfiguration wird nicht überschrieben."
    exit 1
fi

echo ""
echo "============================================"
echo " WireGuard Konfiguration erstellen"
echo "============================================"
echo ""

# Port für wg0 abfragen
read -p "UDP-Port für wg0 [Standard: 80]: " WG0_PORT
WG0_PORT=${WG0_PORT:-80}

# Port für wg1 abfragen
read -p "UDP-Port für wg1 [Standard: 443]: " WG1_PORT
WG1_PORT=${WG1_PORT:-443}

# Netzwerk für wg0 abfragen
read -p "Netzwerk für wg0 [Standard: 172.31.255.0/24]: " WG0_SUBNET
WG0_SUBNET=${WG0_SUBNET:-172.31.255.0/24}

# Netzwerk für wg1 abfragen
read -p "Netzwerk für wg1 [Standard: 172.30.255.0/24]: " WG1_SUBNET
WG1_SUBNET=${WG1_SUBNET:-172.30.255.0/24}

# Basis-IPs aus Subnetz ableiten
WG0_BASE_IP=$(echo $WG0_SUBNET | cut -d'/' -f1 | sed 's/\.[0-9]*$//')
WG0_SERVER_IP="${WG0_BASE_IP}.1"
WG0_DNS="${WG0_BASE_IP}.1"

WG1_BASE_IP=$(echo $WG1_SUBNET | cut -d'/' -f1 | sed 's/\.[0-9]*$//')
WG1_SERVER_IP="${WG1_BASE_IP}.1"
WG1_DNS="${WG1_BASE_IP}.1"

echo ""
echo "[wg-create-cfg] Konfiguration:"
echo "  wg0: Port $WG0_PORT | Netz $WG0_SUBNET | Server-IP $WG0_SERVER_IP"
echo "  wg1: Port $WG1_PORT | Netz $WG1_SUBNET | Server-IP $WG1_SERVER_IP"
echo "  WAN: $WAN_DNS"
echo ""

# Verzeichnisstruktur erstellen
echo "[wg-create-cfg] Erstelle Verzeichnisstruktur ..."
mkdir -p /etc/config/cfg/wireguard

for i in $(seq 1 20); do
    NUM=$(printf "%02d" $i)
    mkdir -p /etc/config/cfg/wireguard/wg0-clients/$NUM
    mkdir -p /etc/config/cfg/wireguard/wg1-clients/$NUM
done

# =============================================================================
# Server-Schlüssel generieren
# =============================================================================
echo "[wg-create-cfg] Generiere Server-Schlüssel ..."

cd /etc/config/cfg/wireguard

# wg0 Server-Schlüssel
wg genkey | tee privatekey-${WG0_PORT} | wg pubkey > publickey-${WG0_PORT}
chmod 600 privatekey-${WG0_PORT}
WG0_SERVER_PRIVKEY=$(cat privatekey-${WG0_PORT})
WG0_SERVER_PUBKEY=$(cat publickey-${WG0_PORT})

# wg1 Server-Schlüssel
wg genkey | tee privatekey-${WG1_PORT} | wg pubkey > publickey-${WG1_PORT}
chmod 600 privatekey-${WG1_PORT}
WG1_SERVER_PRIVKEY=$(cat privatekey-${WG1_PORT})
WG1_SERVER_PUBKEY=$(cat publickey-${WG1_PORT})

echo "[wg-create-cfg] Server PublicKey wg0 (Port $WG0_PORT): $WG0_SERVER_PUBKEY"
echo "[wg-create-cfg] Server PublicKey wg1 (Port $WG1_PORT): $WG1_SERVER_PUBKEY"

# =============================================================================
# Client-Schlüssel und Konfigurationen generieren
# =============================================================================
echo "[wg-create-cfg] Generiere Client-Schlüssel und Konfigurationen ..."

# --- wg0 Clients ---
for i in $(seq 1 20); do
    NUM=$(printf "%02d" $i)
    CLIENT_IP="${WG0_BASE_IP}.$((i + 1))"
    CLIENT_DIR="/etc/config/cfg/wireguard/wg0-clients/$NUM"

    # Schlüssel generieren
    cd $CLIENT_DIR
    wg genkey | tee privatekey | wg pubkey > publickey
    chmod 600 privatekey
    CLIENT_PRIVKEY=$(cat privatekey)
    CLIENT_PUBKEY=$(cat publickey)

    # Config ohne IPv6
    cat > config${NUM}-ohne-ipv6.conf << EOF
[Interface]
Address = ${CLIENT_IP}
DNS = ${WG0_DNS}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = 0.0.0.0/0
Endpoint = ${WAN_DNS}:${WG0_PORT}
PersistentKeepalive = 25
PublicKey = ${WG0_SERVER_PUBKEY}
EOF

    # Config mit IPv6
    cat > config${NUM}-mit-ipv6.conf << EOF
[Interface]
Address = ${CLIENT_IP}
DNS = ${WG0_DNS}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${WAN_DNS}:${WG0_PORT}
PersistentKeepalive = 25
PublicKey = ${WG0_SERVER_PUBKEY}
EOF

    # QR-Codes generieren
    qrencode -o client${NUM}-ohne-ipv6.png -t PNG -s 6 < config${NUM}-ohne-ipv6.conf
    qrencode -o client${NUM}-mit-ipv6.png  -t PNG -s 6 < config${NUM}-mit-ipv6.conf

    echo "[wg-create-cfg] wg0 Client $NUM: $CLIENT_IP"
done

# --- wg1 Clients ---
for i in $(seq 1 20); do
    NUM=$(printf "%02d" $i)
    CLIENT_IP="${WG1_BASE_IP}.$((i + 1))"
    CLIENT_DIR="/etc/config/cfg/wireguard/wg1-clients/$NUM"

    # Schlüssel generieren
    cd $CLIENT_DIR
    wg genkey | tee privatekey | wg pubkey > publickey
    chmod 600 privatekey
    CLIENT_PRIVKEY=$(cat privatekey)
    CLIENT_PUBKEY=$(cat publickey)

    # Config ohne IPv6
    cat > config${NUM}-ohne-ipv6.conf << EOF
[Interface]
Address = ${CLIENT_IP}
DNS = ${WG1_DNS}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = 0.0.0.0/0
Endpoint = ${WAN_DNS}:${WG1_PORT}
PersistentKeepalive = 25
PublicKey = ${WG1_SERVER_PUBKEY}
EOF

    # Config mit IPv6
    cat > config${NUM}-mit-ipv6.conf << EOF
[Interface]
Address = ${CLIENT_IP}
DNS = ${WG1_DNS}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${WAN_DNS}:${WG1_PORT}
PersistentKeepalive = 25
PublicKey = ${WG1_SERVER_PUBKEY}
EOF

    # QR-Codes generieren
    qrencode -o client${NUM}-ohne-ipv6.png -t PNG -s 6 < config${NUM}-ohne-ipv6.conf
    qrencode -o client${NUM}-mit-ipv6.png  -t PNG -s 6 < config${NUM}-mit-ipv6.conf

    echo "[wg-create-cfg] wg1 Client $NUM: $CLIENT_IP"
done

# =============================================================================
# Server-Konfigurationen wg0.conf und wg1.conf erstellen
# =============================================================================
echo "[wg-create-cfg] Erstelle Server-Konfigurationen ..."

# wg0.conf
cat > /etc/config/cfg/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = ${WG0_SERVER_PRIVKEY}
Address = ${WG0_SERVER_IP}/24
ListenPort = ${WG0_PORT}

EOF

for i in $(seq 1 20); do
    NUM=$(printf "%02d" $i)
    CLIENT_PUBKEY=$(cat /etc/config/cfg/wireguard/wg0-clients/$NUM/publickey)
    CLIENT_IP="${WG0_BASE_IP}.$((i + 1))"
    cat >> /etc/config/cfg/wireguard/wg0.conf << EOF
# client${NUM}
[Peer]
PublicKey = ${CLIENT_PUBKEY}
AllowedIPs = ${CLIENT_IP}

EOF
done

# wg1.conf
cat > /etc/config/cfg/wireguard/wg1.conf << EOF
[Interface]
PrivateKey = ${WG1_SERVER_PRIVKEY}
Address = ${WG1_SERVER_IP}/24
ListenPort = ${WG1_PORT}

EOF

for i in $(seq 1 20); do
    NUM=$(printf "%02d" $i)
    CLIENT_PUBKEY=$(cat /etc/config/cfg/wireguard/wg1-clients/$NUM/publickey)
    CLIENT_IP="${WG1_BASE_IP}.$((i + 1))"
    cat >> /etc/config/cfg/wireguard/wg1.conf << EOF
# client${NUM}
[Peer]
PublicKey = ${CLIENT_PUBKEY}
AllowedIPs = ${CLIENT_IP}

EOF
done

# =============================================================================
# Abschlussbericht
# =============================================================================
echo ""
echo "============================================"
echo " Konfiguration erfolgreich erstellt!"
echo "============================================"
echo ""
echo "  Verzeichnis : /etc/config/cfg/wireguard/"
echo "  wg0         : Port $WG0_PORT | $WG0_SUBNET | Endpoint: $WAN_DNS:$WG0_PORT"
echo "  wg1         : Port $WG1_PORT | $WG1_SUBNET | Endpoint: $WAN_DNS:$WG1_PORT"
echo "  Clients     : 20 pro Interface (je 2 Configs + 2 QR-Codes)"
echo ""
echo "  Nächster Schritt: Konfiguration nach /etc/wireguard/ kopieren"
echo "  und firewall.sh neu starten."
echo ""
