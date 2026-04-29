#!/bin/bash

# =============================================================================
# wg-transfer-cfg.sh - WireGuard Konfiguration nach /etc/wireguard/ übertragen
# =============================================================================
# Ablageort : /etc/config/scripts/wg-transfer-cfg.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-transfer-cfg.sh
# Aufgabe   : Kopiert wg0.conf und wg1.conf aus /etc/config/cfg/wireguard/
#             nach /etc/wireguard/ und startet die Interfaces neu
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

# Prüfen ob Gateway-Modus aktiv ist
if [ -f /etc/config/cfg/gateway ]; then
    echo "FEHLER: Gateway-Modus ist aktiv!"
    echo "       wg-transfer-cfg.sh darf nicht auf einem Gateway-Server ausgeführt werden."
    exit 1
fi

# Prüfen ob /etc/wireguard/ existiert
if [ ! -d /etc/wireguard ]; then
    echo "FEHLER: /etc/wireguard/ existiert nicht!"
    echo "       Bitte zuerst wg-install.sh ausführen."
    exit 1
fi

# Prüfen ob Quell-Konfigurationen vorhanden sind
WG0_SRC="/etc/config/cfg/wireguard/wg0.conf"
WG1_SRC="/etc/config/cfg/wireguard/wg1.conf"

if [ ! -f "$WG0_SRC" ] && [ ! -f "$WG1_SRC" ]; then
    echo "FEHLER: Keine Konfigurationsdateien in /etc/config/cfg/wireguard/ gefunden!"
    echo "       Bitte zuerst wg-create-cfg.sh ausführen."
    exit 1
fi

echo ""
echo "============================================"
echo " WireGuard Konfiguration übertragen"
echo "============================================"
echo ""

# Warnung bei bestehenden Konfigurationen
if [ -f /etc/wireguard/wg0.conf ] || [ -f /etc/wireguard/wg1.conf ]; then
    echo "⚠️  WARNUNG: Bestehende Konfigurationen in /etc/wireguard/ gefunden!"
    [ -f /etc/wireguard/wg0.conf ] && echo "    → /etc/wireguard/wg0.conf"
    [ -f /etc/wireguard/wg1.conf ] && echo "    → /etc/wireguard/wg1.conf"
    echo ""
    echo "    Diese Dateien werden überschrieben!"
    echo ""
    read -p "    Trotzdem fortfahren? [ja/NEIN]: " confirm
    if [ "$confirm" != "ja" ]; then
        echo "[wg-transfer-cfg] Abbruch — nichts wurde kopiert."
        exit 1
    fi
    echo ""
fi

# wg0.conf kopieren
if [ -f "$WG0_SRC" ]; then
    echo "[wg-transfer-cfg] Kopiere wg0.conf nach /etc/wireguard/ ..."
    cp "$WG0_SRC" /etc/wireguard/wg0.conf
    chmod 600 /etc/wireguard/wg0.conf
    if [ $? -ne 0 ]; then
        echo "FEHLER: Kopieren von wg0.conf fehlgeschlagen!"
        exit 1
    fi
    echo "[wg-transfer-cfg] wg0.conf erfolgreich kopiert."
fi

# wg1.conf kopieren
if [ -f "$WG1_SRC" ]; then
    echo "[wg-transfer-cfg] Kopiere wg1.conf nach /etc/wireguard/ ..."
    cp "$WG1_SRC" /etc/wireguard/wg1.conf
    chmod 600 /etc/wireguard/wg1.conf
    if [ $? -ne 0 ]; then
        echo "FEHLER: Kopieren von wg1.conf fehlgeschlagen!"
        exit 1
    fi
    echo "[wg-transfer-cfg] wg1.conf erfolgreich kopiert."
fi

# WireGuard Interfaces neu starten falls aktiv
echo ""
echo "[wg-transfer-cfg] Prüfe WireGuard Interfaces ..."

if ip link show wg0 &>/dev/null; then
    echo "[wg-transfer-cfg] Interface wg0 läuft — starte neu ..."
    wg-quick down wg0 > /dev/null 2>&1
    wg-quick up wg0 > /dev/null 2>&1
    echo "[wg-transfer-cfg] Interface wg0 neu gestartet."
else
    echo "[wg-transfer-cfg] Interface wg0 läuft nicht — kein Neustart nötig."
fi

if ip link show wg1 &>/dev/null; then
    echo "[wg-transfer-cfg] Interface wg1 läuft — starte neu ..."
    wg-quick down wg1 > /dev/null 2>&1
    wg-quick up wg1 > /dev/null 2>&1
    echo "[wg-transfer-cfg] Interface wg1 neu gestartet."
else
    echo "[wg-transfer-cfg] Interface wg1 läuft nicht — kein Neustart nötig."
fi

echo ""
echo "============================================"
echo " Übertragung erfolgreich abgeschlossen!"
echo "============================================"
echo ""
echo "  Quelle : /etc/config/cfg/wireguard/"
echo "  Ziel   : /etc/wireguard/"
echo ""
echo "  Hinweis: WireGuard wird durch firewall.sh gestartet."
echo "           Bitte firewall.sh neu starten um die Interfaces zu aktivieren."
echo ""
