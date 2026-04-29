#!/bin/bash

# =============================================================================
# wg-transfer-gw.sh - WireGuard Gateway Konfiguration nach /etc/wireguard/ übertragen
# =============================================================================
# Ablageort : /etc/config/scripts/wg-transfer-gw.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-transfer-gw.sh
# Aufgabe   : Kopiert wg2.conf, wg3.conf, wg4.conf, wg5.conf aus
#             /etc/config/cfg/wireguard-gw/ nach /etc/wireguard/
# =============================================================================

# Root-Check
if [[ $EUID -ne 0 ]]; then
    echo "FEHLER: Dieses Script muss als root ausgeführt werden!"
    exit 1
fi

# Prüfen ob Gateway-Modus aktiv ist — NUR auf GW-Server erlaubt!
if [ ! -f /etc/config/cfg/gateway ]; then
    echo "FEHLER: Kein Gateway-Modus aktiv!"
    echo "       wg-transfer-gw.sh darf nur auf einem Gateway-Server ausgeführt werden."
    exit 1
fi

# Prüfen ob WireGuard installiert ist
if ! command -v wg &>/dev/null; then
    echo "FEHLER: WireGuard ist nicht installiert!"
    echo "       Bitte zuerst wg-install.sh ausführen."
    exit 1
fi

# Prüfen ob /etc/wireguard/ existiert
if [ ! -d /etc/wireguard ]; then
    echo "FEHLER: /etc/wireguard/ existiert nicht!"
    echo "       Bitte zuerst wg-install.sh ausführen."
    exit 1
fi

# Prüfen ob Quell-Konfigurationen vorhanden sind
SRC_DIR="/etc/config/cfg/wireguard-gw"
if [ ! -d "$SRC_DIR" ]; then
    echo "FEHLER: $SRC_DIR nicht gefunden!"
    echo "       Bitte zuerst wg-create-gw.sh ausführen."
    exit 1
fi

# Prüfen welche conf-Dateien vorhanden sind
CONFS=()
for iface in wg2 wg3 wg4 wg5; do
    if [ -f "$SRC_DIR/${iface}.conf" ]; then
        CONFS+=("$iface")
    fi
done

if [ ${#CONFS[@]} -eq 0 ]; then
    echo "FEHLER: Keine wg2.conf - wg5.conf in $SRC_DIR gefunden!"
    echo "       Bitte zuerst wg-create-gw.sh ausführen."
    exit 1
fi

echo ""
echo "============================================"
echo " WireGuard Gateway Konfiguration übertragen"
echo "============================================"
echo ""
echo "[wg-transfer-gw] Gefundene Konfigurationen: ${CONFS[@]}"
echo ""

# Warnung bei bestehenden Konfigurationen
EXISTING=()
for iface in "${CONFS[@]}"; do
    if [ -f /etc/wireguard/${iface}.conf ]; then
        EXISTING+=("${iface}.conf")
    fi
done

if [ ${#EXISTING[@]} -gt 0 ]; then
    echo "⚠️  WARNUNG: Bestehende Konfigurationen in /etc/wireguard/ gefunden!"
    for f in "${EXISTING[@]}"; do
        echo "    → /etc/wireguard/$f"
    done
    echo ""
    echo "    Diese Dateien werden überschrieben!"
    echo ""
    read -p "    Trotzdem fortfahren? [ja/NEIN]: " confirm
    if [ "$confirm" != "ja" ]; then
        echo "[wg-transfer-gw] Abbruch — nichts wurde kopiert."
        exit 1
    fi
    echo ""
fi

# Konfigurationen kopieren
for iface in "${CONFS[@]}"; do
    echo "[wg-transfer-gw] Kopiere ${iface}.conf nach /etc/wireguard/ ..."
    cp "$SRC_DIR/${iface}.conf" /etc/wireguard/${iface}.conf
    chmod 600 /etc/wireguard/${iface}.conf
    if [ $? -ne 0 ]; then
        echo "FEHLER: Kopieren von ${iface}.conf fehlgeschlagen!"
        exit 1
    fi
    echo "[wg-transfer-gw] ${iface}.conf erfolgreich kopiert."
done

# Service-Datei anlegen wenn nicht vorhanden
if [ ! -f /etc/wireguard/service ]; then
    echo "[wg-transfer-gw] Lege service Referenzdatei in /etc/wireguard an ..."
    cat > /etc/wireguard/service << 'SVCEOF'
# Install Wireguard and Tools
dpkg -i /etc/config/deb/wireguard_1.1_all.deb
dpkg -i /etc/config/web/wireguard-tools_1.1_amd64.deb
# Achtung : Werden die 2 oben genannten Packete über die
# offiziellen Packetquellen installiert wird als eine
# Abhängigkeit der Realtime Kernel installiert !!!!
# Dies sollte unbedingt vermieden werden !!!!!
# Welche zusätzliche Software muss installiert werden ?
apt-get install qrencode
# Welcher Befehl erzeugt ein neues Schlüsselpaar =
wg genkey | tee privatekey | wg pubkey > publickey
# Disable Service
systemctl disable wg-quick@wg0
systemctl disable wg-quick@wg1
# Start Service
systemctl start wg-quick@wg0
systemctl start wg-quick@wg1
SVCEOF
fi

echo ""

# WireGuard Interfaces neu starten falls aktiv
echo "[wg-transfer-gw] Prüfe WireGuard Interfaces ..."
for iface in "${CONFS[@]}"; do
    if ip link show $iface &>/dev/null; then
        echo "[wg-transfer-gw] Interface $iface läuft — starte neu ..."
        wg-quick down $iface > /dev/null 2>&1
        wg-quick up   $iface > /dev/null 2>&1
        echo "[wg-transfer-gw] Interface $iface neu gestartet."
    else
        echo "[wg-transfer-gw] Interface $iface läuft nicht — kein Neustart nötig."
    fi
done

echo ""
echo "============================================"
echo " Übertragung erfolgreich abgeschlossen!"
echo "============================================"
echo ""
echo "  Quelle : /etc/config/cfg/wireguard-gw/"
echo "  Ziel   : /etc/wireguard/"
echo "  Dateien: ${CONFS[@]}"
echo ""
echo "  Hinweis: WireGuard wird durch gateway.sh gestartet."
echo "           Bitte gateway.sh neu starten um die Interfaces zu aktivieren."
echo ""
