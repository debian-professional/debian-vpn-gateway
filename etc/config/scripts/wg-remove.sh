#!/bin/bash

# =============================================================================
# wg-remove.sh - WireGuard Deinstallations Script
# =============================================================================
# Ablageort : /etc/config/scripts/wg-remove.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-remove.sh
# Aufgabe   : Vollständige Deinstallation von WireGuard und qrencode
#             Löschen aller Schlüssel und Konfigurationsdateien
#             Unterstützt Standard-Server (wg0/wg1) und Gateway-Server (wg2-wg5)
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
FOUND_CONFIGS=""
for IFACE in wg0 wg1 wg2 wg3 wg4 wg5; do
    if [ -f /etc/wireguard/${IFACE}.conf ]; then
        FOUND_CONFIGS="$FOUND_CONFIGS /etc/wireguard/${IFACE}.conf"
    fi
done

if [ -n "$FOUND_CONFIGS" ]; then
    echo ""
    echo "⚠️  WARNUNG: Aktive WireGuard Konfigurationen gefunden!"
    for CONF in $FOUND_CONFIGS; do
        echo "    → $CONF"
    done
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
for IFACE in wg0 wg1 wg2 wg3 wg4 wg5; do
    if ip link show $IFACE &>/dev/null; then
        wg-quick down $IFACE > /dev/null 2>&1
        echo "[wg-remove] Interface $IFACE gestoppt."
    fi
done

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
