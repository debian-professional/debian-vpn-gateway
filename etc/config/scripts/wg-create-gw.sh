#!/bin/bash

# =============================================================================
# wg-create-gw.sh - WireGuard Gateway Konfiguration erstellen
# =============================================================================
# Ablageort : /etc/config/scripts/wg-create-gw.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-create-gw.sh
# Aufgabe   : Erstellt WireGuard Konfigurationen für den Gateway-Modus
#             (wg2, wg3, wg4, wg5) basierend auf /etc/config/cfg/gateway
#             mit je 20 Clients (Schlüssel, Config-Dateien, QR-Codes)
#             Zielverzeichnis: /etc/config/cfg/wireguard-gw/
# =============================================================================

# Root-Check
if [[ $EUID -ne 0 ]]; then
    echo "FEHLER: Dieses Script muss als root ausgeführt werden!"
    exit 1
fi

# Prüfen ob Gateway-Modus aktiv ist — NUR auf GW-Server erlaubt!
if [ ! -f /etc/config/cfg/gateway ]; then
    echo "FEHLER: Kein Gateway-Modus aktiv!"
    echo "       wg-create-gw.sh darf nur auf einem Gateway-Server ausgeführt werden."
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

# Prüfen ob bereits eine GW-Konfiguration existiert
if [ -d /etc/config/cfg/wireguard-gw ] && [ -n "$(ls -A /etc/config/cfg/wireguard-gw 2>/dev/null)" ]; then
    echo "FEHLER: /etc/config/cfg/wireguard-gw/ existiert bereits und ist nicht leer!"
    echo "       Eine bestehende Konfiguration wird nicht überschrieben."
    exit 1
fi

# Gateway-Datei einlesen
GATEWAY_FILE="/etc/config/cfg/gateway"
GW_LINES=$(grep -v '^#' "$GATEWAY_FILE" | grep -v '^[[:space:]]*$')
GW_COUNT=$(echo "$GW_LINES" | wc -l)

echo ""
echo "============================================"
echo " WireGuard Gateway Konfiguration erstellen"
echo "============================================"
echo ""
echo "[wg-create-gw] WAN-Hostname  : $WAN_DNS"
echo "[wg-create-gw] Gateway-Zeilen: $GW_COUNT"
echo ""

# UDP-Ports für jedes WG-Interface abfragen
echo "UDP-Ports für die WireGuard Gateway-Interfaces:"
echo ""

WG_PORTS=()
WG_IFACE_NUM=2
while IFS= read -r line; do
    COUNTRY=$(echo "$line" | awk '{print $2}')
    read -p "  UDP-Port für wg${WG_IFACE_NUM} ($COUNTRY) [Standard: $((8000 + WG_IFACE_NUM))]: " PORT
    PORT=${PORT:-$((8000 + WG_IFACE_NUM))}
    WG_PORTS+=("$PORT")
    WG_IFACE_NUM=$((WG_IFACE_NUM + 1))
done <<< "$GW_LINES"

echo ""
echo "============================================"
echo " Konfiguration:"
echo "============================================"

WG_IFACE_NUM=2
IDX=0
while IFS= read -r line; do
    COUNTRY=$(echo "$line" | awk '{print $2}')
    IP_RANGE=$(echo "$line" | awk '{print $3}')
    SERVER_IP=$(echo "$line" | awk '{print $7}')
    PORT=${WG_PORTS[$IDX]}
    echo "  wg${WG_IFACE_NUM}: $COUNTRY | Netz: $(echo $IP_RANGE | cut -d'-' -f1 | sed 's/\.[0-9]*$/.0')/24 | Server-IP: $SERVER_IP | Port: $PORT"
    WG_IFACE_NUM=$((WG_IFACE_NUM + 1))
    IDX=$((IDX + 1))
done <<< "$GW_LINES"

echo ""

# Verzeichnisstruktur erstellen
echo "[wg-create-gw] Erstelle Verzeichnisstruktur ..."
mkdir -p /etc/config/cfg/wireguard-gw

WG_IFACE_NUM=2
while IFS= read -r line; do
    for i in $(seq 1 20); do
        NUM=$(printf "%02d" $i)
        mkdir -p /etc/config/cfg/wireguard-gw/wg${WG_IFACE_NUM}-clients/$NUM
    done
    WG_IFACE_NUM=$((WG_IFACE_NUM + 1))
done <<< "$GW_LINES"

# =============================================================================
# Pro Gateway-Zeile: Server-Schlüssel + Clients generieren
# =============================================================================

WG_IFACE_NUM=2
IDX=0
while IFS= read -r line; do

    COUNTRY=$(echo "$line"   | awk '{print $2}')
    IP_RANGE=$(echo "$line"  | awk '{print $3}')
    SERVER_IP=$(echo "$line" | awk '{print $7}')
    PORT=${WG_PORTS[$IDX]}

    # Basis-IP aus IP-Range ableiten (z.B. 172.25.255)
    BASE_IP=$(echo "$IP_RANGE" | cut -d'-' -f1 | sed 's/\.[0-9]*$//')

    echo ""
    echo "[wg-create-gw] === wg${WG_IFACE_NUM} ($COUNTRY) | Port $PORT | $BASE_IP.0/24 ==="

    # Server-Schlüssel generieren
    echo "[wg-create-gw] Generiere Server-Schlüssel ..."
    cd /etc/config/cfg/wireguard-gw
    wg genkey | tee privatekey-${PORT} | wg pubkey > publickey-${PORT}
    chmod 600 privatekey-${PORT}
    SERVER_PRIVKEY=$(cat privatekey-${PORT})
    SERVER_PUBKEY=$(cat  publickey-${PORT})
    echo "[wg-create-gw] Server PublicKey wg${WG_IFACE_NUM}: $SERVER_PUBKEY"

    # Server wg?.conf erstellen (Kopf)
    cat > /etc/config/cfg/wireguard-gw/wg${WG_IFACE_NUM}.conf << EOF
[Interface]
PrivateKey = ${SERVER_PRIVKEY}
Address = ${SERVER_IP}/24
ListenPort = ${PORT}

EOF

    # 20 Clients generieren
    echo "[wg-create-gw] Generiere 20 Clients ..."
    for i in $(seq 1 20); do
        NUM=$(printf "%02d" $i)
        CLIENT_IP="${BASE_IP}.$((i + 1))"
        CLIENT_DIR="/etc/config/cfg/wireguard-gw/wg${WG_IFACE_NUM}-clients/$NUM"

        cd "$CLIENT_DIR"

        # Client-Schlüssel generieren
        wg genkey | tee privatekey | wg pubkey > publickey
        chmod 600 privatekey
        CLIENT_PRIVKEY=$(cat privatekey)
        CLIENT_PUBKEY=$(cat  publickey)

        # Config ohne IPv6
        cat > config${NUM}-ohne-ipv6.conf << EOF
[Interface]
Address = ${CLIENT_IP}/32
DNS = ${SERVER_IP}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = 0.0.0.0/0
Endpoint = ${WAN_DNS}:${PORT}
PersistentKeepalive = 25
PublicKey = ${SERVER_PUBKEY}
EOF

        # Config mit IPv6
        cat > config${NUM}-mit-ipv6.conf << EOF
[Interface]
Address = ${CLIENT_IP}/32
DNS = ${SERVER_IP}
PrivateKey = ${CLIENT_PRIVKEY}
[Peer]
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${WAN_DNS}:${PORT}
PersistentKeepalive = 25
PublicKey = ${SERVER_PUBKEY}
EOF

        # QR-Codes generieren
        qrencode -o client${NUM}-ohne-ipv6.png -t PNG -s 6 < config${NUM}-ohne-ipv6.conf
        qrencode -o client${NUM}-mit-ipv6.png  -t PNG -s 6 < config${NUM}-mit-ipv6.conf

        # Peer-Block zur Server-Config hinzufügen
        cat >> /etc/config/cfg/wireguard-gw/wg${WG_IFACE_NUM}.conf << EOF
# client${NUM}
[Peer]
PublicKey = ${CLIENT_PUBKEY}
AllowedIPs = ${CLIENT_IP}

EOF

        echo "[wg-create-gw] wg${WG_IFACE_NUM} Client $NUM: $CLIENT_IP"
    done

    WG_IFACE_NUM=$((WG_IFACE_NUM + 1))
    IDX=$((IDX + 1))

done <<< "$GW_LINES"

# =============================================================================
# Abschlussbericht
# =============================================================================
echo ""
echo "============================================"
echo " Gateway Konfiguration erfolgreich erstellt!"
echo "============================================"
echo ""
echo "  Verzeichnis : /etc/config/cfg/wireguard-gw/"
echo ""

WG_IFACE_NUM=2
IDX=0
while IFS= read -r line; do
    COUNTRY=$(echo "$line" | awk '{print $2}')
    PORT=${WG_PORTS[$IDX]}
    echo "  wg${WG_IFACE_NUM}: $COUNTRY | Port $PORT | Endpoint: $WAN_DNS:$PORT"
    WG_IFACE_NUM=$((WG_IFACE_NUM + 1))
    IDX=$((IDX + 1))
done <<< "$GW_LINES"

echo ""
echo "  Clients : 20 pro Interface (je 2 Configs + 2 QR-Codes)"
echo ""
echo "  Hinweis : Konfigurationen nach /etc/wireguard/ übertragen"
echo "            und firewall.sh / gateway.sh neu starten."
echo ""
