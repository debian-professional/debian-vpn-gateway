#!/bin/bash

# =============================================================================
# wg-install.sh - WireGuard Installation Script
# =============================================================================
# Ablageort : /etc/config/scripts/wg-install.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-install.sh
# Aufgabe   : Installation von WireGuard und qrencode
#             Deaktivierung der systemd WireGuard Services
# =============================================================================

# Root-Check
if [[ $EUID -ne 0 ]]; then
    echo "FEHLER: Dieses Script muss als root ausgeführt werden!"
    exit 1
fi

# Prüfen ob WireGuard bereits installiert ist
if command -v wg &>/dev/null; then
    echo "FEHLER: WireGuard ist bereits installiert!"
    exit 1
fi


# WireGuard Pakete installieren

echo "[wg-install] Installiere wireguard-tools ..."
dpkg -i /etc/config/deb/wireguard-tools_1.1_amd64.deb
if [ $? -ne 0 ]; then
    echo "FEHLER: Installation von wireguard-tools_1.1_amd64.deb fehlgeschlagen!"
    exit 1
fi

# WireGuard Pakete installieren

echo "[wg-install] Installiere wireguard ..."
dpkg -i /etc/config/deb/wireguard_1.1_all.deb
if [ $? -ne 0 ]; then
    echo "FEHLER: Installation von wireguard_1.1_all.deb fehlgeschlagen!"
    exit 1
fi

# qrencode installieren
echo "[wg-install] Installiere qrencode ..."
apt-get install -y qrencode
if [ $? -ne 0 ]; then
    echo "FEHLER: Installation von qrencode fehlgeschlagen!"
    exit 1
fi

# systemd Services deaktivieren
# WireGuard wird ausschliesslich durch firewall.sh oder gateway.sh gestartet!
echo "[wg-install] Deaktiviere systemd WireGuard Services ..."
systemctl disable wg-quick@wg0 > /dev/null 2>&1
systemctl disable wg-quick@wg1 > /dev/null 2>&1

# Service-Datei anlegen wenn /etc/wireguard leer ist
if [ -d /etc/wireguard ] && [ -z "$(ls -A /etc/wireguard)" ]; then
    echo "[wg-install] Lege service Referenzdatei in /etc/wireguard an ..."
    cat > /etc/wireguard/service << 'EOF'
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
EOF
fi

echo "[wg-install] Installation erfolgreich abgeschlossen."
echo "[wg-install] WireGuard Version: $(wg --version)"
echo "[wg-install] Hinweis: WireGuard wird ausschliesslich durch firewall.sh oder gateway.sh gestartet!"
