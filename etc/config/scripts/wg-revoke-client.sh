#!/bin/bash

# =============================================================================
# wg-revoke-client.sh - WireGuard Client sperren und entfernen
# =============================================================================
# Ablageort : /etc/config/scripts/wg-revoke-client.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-revoke-client.sh
# Aufgabe   : Entfernt einen WireGuard Client aus den WG-Interfaces
#             sowie alle zugehörigen Dateien und Verzeichnisse
#             Funktioniert auf Standard-Servern (wg0/wg1) UND Gateway-Servern (wg2-wg5)
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

# Modus erkennen: Standard-Server oder Gateway-Server
IS_GATEWAY=0
if [ -f /etc/config/cfg/gateway ]; then
    IS_GATEWAY=1
fi

# Konfigurationsverzeichnis bestimmen
if [ $IS_GATEWAY -eq 1 ]; then
    CFG_DIR="/etc/config/cfg/wireguard-gw"
    if [ ! -d "$CFG_DIR" ]; then
        echo "FEHLER: $CFG_DIR nicht gefunden!"
        echo "       Bitte zuerst wg-create-gw.sh ausführen."
        exit 1
    fi
else
    CFG_DIR="/etc/config/cfg/wireguard"
    if [ ! -d "$CFG_DIR" ]; then
        echo "FEHLER: $CFG_DIR nicht gefunden!"
        echo "       Bitte zuerst wg-create-cfg.sh ausführen."
        exit 1
    fi
fi

echo ""
echo "============================================"
echo " WireGuard Client sperren"
if [ $IS_GATEWAY -eq 1 ]; then
    echo " Modus: Gateway-Server"
else
    echo " Modus: Standard-Server"
fi
echo "============================================"
echo ""

# Interface abfragen
echo "Welches Interface?"
if [ $IS_GATEWAY -eq 1 ]; then
    echo "  1) wg2 (Port 80)   — Deutschland"
    echo "  2) wg3 (Port 443)  — UK"
    echo "  3) wg4 (Port 4500) — Schweiz"
    echo "  4) wg5 (Port 8080) — Spanien"
    echo "  5) Alle (wg2 + wg3 + wg4 + wg5)"
    echo ""
    read -p "Auswahl [1-5]: " IFACE_CHOICE
    case $IFACE_CHOICE in
        1) INTERFACES="wg2" ;;
        2) INTERFACES="wg3" ;;
        3) INTERFACES="wg4" ;;
        4) INTERFACES="wg5" ;;
        5) INTERFACES="wg2 wg3 wg4 wg5" ;;
        *)
            echo "FEHLER: Ungültige Auswahl — bitte 1 bis 5 eingeben."
            exit 1
            ;;
    esac
else
    echo "  1) wg0 (Port 80)"
    echo "  2) wg1 (Port 443)"
    echo "  3) Beide (wg0 + wg1)"
    echo ""
    read -p "Auswahl [1-3]: " IFACE_CHOICE
    case $IFACE_CHOICE in
        1) INTERFACES="wg0" ;;
        2) INTERFACES="wg1" ;;
        3) INTERFACES="wg0 wg1" ;;
        *)
            echo "FEHLER: Ungültige Auswahl — bitte 1, 2 oder 3 eingeben."
            exit 1
            ;;
    esac
fi

# Client-Nummer abfragen
echo ""
while true; do
    read -p "Welcher Client soll gesperrt werden? [01-20]: " CLIENT_NR
    CLIENT_NR=$(printf "%02d" $((10#$CLIENT_NR)) 2>/dev/null)
    if [[ "$CLIENT_NR" =~ ^[0-9]{2}$ ]] && [ "$((10#$CLIENT_NR))" -ge 1 ] && [ "$((10#$CLIENT_NR))" -le 20 ]; then
        break
    else
        echo "FEHLER: Ungültige Eingabe — bitte eine Zahl zwischen 01 und 20 eingeben."
    fi
done

echo ""

# Sicherheitsabfrage
echo "⚠️  WARNUNG: Folgende Aktion wird ausgeführt:"
for IFACE in $INTERFACES; do
    echo "    → Client $CLIENT_NR wird aus $IFACE entfernt"
    echo "    → $CFG_DIR/${IFACE}-clients/$CLIENT_NR/ wird gelöscht"
done
echo ""
echo "    Diese Aktion kann nicht rückgängig gemacht werden!"
echo ""
read -p "    Trotzdem fortfahren? [ja/NEIN]: " confirm
if [ "$confirm" != "ja" ]; then
    echo "[wg-revoke-client] Abbruch — nichts wurde verändert."
    exit 1
fi

echo ""

# =============================================================================
# Client entfernen
# =============================================================================

for IFACE in $INTERFACES; do

    CONF="$CFG_DIR/${IFACE}.conf"
    CLIENT_DIR="$CFG_DIR/${IFACE}-clients/$CLIENT_NR"

    # Prüfen ob Client-Verzeichnis existiert
    if [ ! -d "$CLIENT_DIR" ]; then
        echo "[wg-revoke-client] WARNUNG: $CLIENT_DIR nicht gefunden — überspringe."
        continue
    fi

    # Public Key des Clients lesen
    CLIENT_PUBKEY=$(cat "$CLIENT_DIR/publickey" | tr -d '[:space:]')
    if [ -z "$CLIENT_PUBKEY" ]; then
        echo "[wg-revoke-client] FEHLER: Public Key von Client $CLIENT_NR nicht lesbar!"
        continue
    fi

    echo "[wg-revoke-client] Entferne Client $CLIENT_NR aus $CONF ..."

    # Peer-Block aus wg?.conf entfernen via Python
    python3 - "$CONF" "$CLIENT_PUBKEY" << 'PYEOF'
import sys

conf_file = sys.argv[1]
pubkey    = sys.argv[2]

with open(conf_file, "r") as f:
    lines = f.readlines()

new_lines = []
skip = False
i = 0
while i < len(lines):
    line = lines[i]
    if line.strip().startswith("# client") and i + 1 < len(lines):
        j = i + 1
        while j < len(lines) and lines[j].strip() == "":
            j += 1
        if j < len(lines) and lines[j].strip() == "[Peer]":
            block = [line]
            k = i + 1
            while k < len(lines):
                block.append(lines[k])
                if lines[k].strip().startswith("PublicKey") and pubkey in lines[k]:
                    k += 1
                    while k < len(lines) and lines[k].strip() != "":
                        k += 1
                    if k < len(lines) and lines[k].strip() == "":
                        k += 1
                    i = k
                    skip = True
                    break
                if lines[k].strip() == "" or (lines[k].strip().startswith("[") and lines[k].strip() != "[Peer]"):
                    break
                k += 1
            if skip:
                skip = False
                continue
    new_lines.append(line)
    i += 1

with open(conf_file, "w") as f:
    f.writelines(new_lines)

print(f"[wg-revoke-client] Peer-Block erfolgreich entfernt.")
PYEOF

    # Client sofort aus aktivem Interface entfernen falls es läuft
    if ip link show $IFACE &>/dev/null; then
        echo "[wg-revoke-client] Interface $IFACE aktiv — entferne Client sofort ..."
        wg set $IFACE peer "$CLIENT_PUBKEY" remove 2>/dev/null
        echo "[wg-revoke-client] Client $CLIENT_NR aus aktivem Interface $IFACE entfernt."
    fi

    # Client-Verzeichnis löschen
    echo "[wg-revoke-client] Lösche $CLIENT_DIR ..."
    rm -rf "$CLIENT_DIR"
    echo "[wg-revoke-client] $CLIENT_DIR gelöscht."

    # wg?.conf nach /etc/wireguard/ synchronisieren falls vorhanden
    if [ -f "/etc/wireguard/${IFACE}.conf" ]; then
        echo "[wg-revoke-client] Synchronisiere ${IFACE}.conf nach /etc/wireguard/ ..."
        cp "$CONF" "/etc/wireguard/${IFACE}.conf"
        chmod 600 "/etc/wireguard/${IFACE}.conf"
        echo "[wg-revoke-client] /etc/wireguard/${IFACE}.conf aktualisiert."
    fi

    echo ""
done

echo "============================================"
echo " Client $CLIENT_NR erfolgreich gesperrt!"
echo "============================================"
echo ""
