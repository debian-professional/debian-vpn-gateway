#!/bin/bash

# =============================================================================
# wg-revoke-client.sh - WireGuard Client sperren und entfernen
# =============================================================================
# Ablageort : /etc/config/scripts/wg-revoke-client.sh
# Aufruf    : sudo bash /etc/config/scripts/wg-revoke-client.sh
# Aufgabe   : Entfernt einen WireGuard Client aus wg0.conf und/oder wg1.conf
#             sowie alle zugehörigen Dateien und Verzeichnisse
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
    echo "       wg-revoke-client.sh darf nicht auf einem Gateway-Server ausgeführt werden."
    exit 1
fi

# Prüfen ob Konfigurationen vorhanden sind
if [ ! -d /etc/config/cfg/wireguard ]; then
    echo "FEHLER: /etc/config/cfg/wireguard/ nicht gefunden!"
    echo "       Bitte zuerst wg-create-cfg.sh ausführen."
    exit 1
fi

echo ""
echo "============================================"
echo " WireGuard Client sperren"
echo "============================================"
echo ""

# Interface abfragen
echo "Welches Interface?"
echo "  1) wg0 (Port 80)"
echo "  2) wg1 (Port 443)"
echo "  3) Beide (Port 80 + Port 443)"
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

# Client-Nummer abfragen
echo ""
while true; do
    read -p "Welcher Client soll gesperrt werden? [01-20]: " CLIENT_NR
    # Führende Null hinzufügen wenn nötig
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
    if [ "$IFACE" = "wg0" ]; then
        echo "    → Client $CLIENT_NR wird aus wg0 (Port 80) entfernt"
        echo "    → /etc/config/cfg/wireguard/wg0-clients/$CLIENT_NR/ wird gelöscht"
    fi
    if [ "$IFACE" = "wg1" ]; then
        echo "    → Client $CLIENT_NR wird aus wg1 (Port 443) entfernt"
        echo "    → /etc/config/cfg/wireguard/wg1-clients/$CLIENT_NR/ wird gelöscht"
    fi
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

    if [ "$IFACE" = "wg0" ]; then
        CONF="/etc/config/cfg/wireguard/wg0.conf"
        CLIENT_DIR="/etc/config/cfg/wireguard/wg0-clients/$CLIENT_NR"
        WG_IFACE="wg0"
    else
        CONF="/etc/config/cfg/wireguard/wg1.conf"
        CLIENT_DIR="/etc/config/cfg/wireguard/wg1-clients/$CLIENT_NR"
        WG_IFACE="wg1"
    fi

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

    # Peer-Block aus wg?.conf entfernen
    # Entfernt den Kommentar # clientXX und den zugehörigen [Peer]-Block
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
    # Kommentarzeile des Clients gefunden
    if line.strip().startswith("# client") and i + 1 < len(lines):
        # Nächste nicht-leere Zeile prüfen ob [Peer]
        j = i + 1
        while j < len(lines) and lines[j].strip() == "":
            j += 1
        if j < len(lines) and lines[j].strip() == "[Peer]":
            # Peer-Block lesen und auf PublicKey prüfen
            block = [line]
            k = i + 1
            while k < len(lines):
                block.append(lines[k])
                if lines[k].strip().startswith("PublicKey") and pubkey in lines[k]:
                    # Dieser Block gehört zum gesuchten Client — überspringen
                    # Bis zur nächsten Leerzeile oder Ende
                    k += 1
                    while k < len(lines) and lines[k].strip() != "":
                        k += 1
                    # Abschliessende Leerzeile auch überspringen
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
    if ip link show $WG_IFACE &>/dev/null; then
        echo "[wg-revoke-client] Interface $WG_IFACE aktiv — entferne Client sofort ..."
        wg set $WG_IFACE peer "$CLIENT_PUBKEY" remove 2>/dev/null
        echo "[wg-revoke-client] Client $CLIENT_NR aus aktivem Interface $WG_IFACE entfernt."
    fi

    # Client-Verzeichnis löschen
    echo "[wg-revoke-client] Lösche $CLIENT_DIR ..."
    rm -rf "$CLIENT_DIR"
    echo "[wg-revoke-client] $CLIENT_DIR gelöscht."

    # wg?.conf nach /etc/wireguard/ synchronisieren falls vorhanden
    if [ -f "/etc/wireguard/${WG_IFACE}.conf" ]; then
        echo "[wg-revoke-client] Synchronisiere ${WG_IFACE}.conf nach /etc/wireguard/ ..."
        cp "$CONF" "/etc/wireguard/${WG_IFACE}.conf"
        chmod 600 "/etc/wireguard/${WG_IFACE}.conf"
        echo "[wg-revoke-client] /etc/wireguard/${WG_IFACE}.conf aktualisiert."
    fi

    echo ""
done

echo "============================================"
echo " Client $CLIENT_NR erfolgreich gesperrt!"
echo "============================================"
echo ""
