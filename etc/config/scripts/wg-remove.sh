#!/bin/bash

# =============================================================================
# wg-remove.sh - WireGuard Deinstallations Script
# =============================================================================
# Ablageort : /etc/config/scripts/wg-remove.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-remove.sh
# Aufgabe   : Vollständige Deinstallation von WireGuard und qrencode
#             Löschen aller Schlüssel und Konfigurationsdateien
# =============================================================================

# Root-Check
if [[ $EUID -ne 0 ]]; then
    echo "FEHLER: Dieses Script muss als root ausgeführt werden!"
    exit 1
fi

# Prüfen ob WireGuard überhaupt installiert ist
if ! command -v wg &>/dev/null; then
    echo "FEHLER: WireGuard ist nicht installiert!"
    exit 1
fi

echo "[wg-remove] Starte vollständige Deinstallation von WireGuard ..."

# Warnung wenn aktive Konfigurationen vorhanden sind — VOR allem anderen!
if [ -f /etc/wireguard/wg0.conf ] || [ -f /etc/wireguard/wg1.conf ]; then
    echo ""
    echo "⚠️  WARNUNG: Aktive WireGuard Konfigurationen gefunden!"
    [ -f /etc/wireguard/wg0.conf ] && echo "    → /etc/wireguard/wg0.conf"
    [ -f /etc/wireguard/wg1.conf ] && echo "    → /etc/wireguard/wg1.conf"
    echo ""
    echo "    Diese Konfigurationen enthalten Schlüssel und Client-Daten"
    echo "    die nach dem Löschen UNWIDERRUFLICH verloren sind!"
    echo ""
    read -p "    Trotzdem fortfahren? [ja/NEIN]: " confirm
    if [ "$confirm" != "ja" ]; then
        echo "[wg-remove] Abbruch — nichts wurde gelöscht."
        exit 1
    fi
    echo ""
fi

# WireGuard Interfaces stoppen falls aktiv
echo "[wg-remove] Stoppe WireGuard Interfaces ..."
if ip link show wg0 &>/dev/null; then
    wg-quick down wg0 > /dev/null 2>&1
    echo "[wg-remove] Interface wg0 gestoppt."
fi
if ip link show wg1 &>/dev/null; then
    wg-quick down wg1 > /dev/null 2>&1
    echo "[wg-remove] Interface wg1 gestoppt."
fi

# Pakete deinstallieren
echo "[wg-remove] Deinstalliere wireguard ..."
dpkg -r wireguard > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "FEHLER: Deinstallation von wireguard fehlgeschlagen!"
    exit 1
fi

echo "[wg-remove] Deinstalliere wireguard-tools ..."
dpkg -r wireguard-tools > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "FEHLER: Deinstallation von wireguard-tools fehlgeschlagen!"
    exit 1
fi

echo "[wg-remove] Deinstalliere qrencode ..."
apt-get remove -y qrencode > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "FEHLER: Deinstallation von qrencode fehlgeschlagen!"
    exit 1
fi

# /etc/wireguard/ komplett löschen
echo "[wg-remove] Lösche /etc/wireguard/ komplett ..."
rm -rf /etc/wireguard/
if [ $? -ne 0 ]; then
    echo "FEHLER: Löschen von /etc/wireguard/ fehlgeschlagen!"
    exit 1
fi

echo "[wg-remove] Deinstallation erfolgreich abgeschlossen."
echo "[wg-remove] WireGuard, wireguard-tools, qrencode und /etc/wireguard/ wurden vollständig entfernt."
