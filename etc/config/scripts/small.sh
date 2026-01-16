#!/bin/bash
# ===================================================================
# OpenStack Performance Tuning – 1 vCPU, 1 GB RAM
# Debian 13 - Optimiert für Single-Core mit minimalem RAM
# ===================================================================
#
# DIESES SKRIPT OPTIMIERT EINE OPENSTACK VM MIT:
# - 1 vCPU (keine Parallelität, nur Task-Switching)
# - 1 GB RAM (sehr begrenzt, daher aggressive Optimierungen)
# - OpenStack/KVM Hypervisor
#
# ZIEL: Maximale Performance trotz extrem limitierter Ressourcen
# FOKUS: Swapping vermeiden, CPU-Kontextwechsel minimieren
# ===================================================================

echo "[INFO] Starte OpenStack 1 vCPU / 1 GB RAM Optimierung..."

# ===================================================================
# 1. SICHERE SYSCTL-FUNKTION
# ===================================================================
safe_sysctl() {
    local param="$1"
    local value="$2"
    local sysctl_path="/proc/sys/${param//./\/}"
    
    if [ -f "$sysctl_path" ] && [ -w "$sysctl_path" ]; then
        if sysctl -w "$param=$value" > /dev/null 2>&1; then
            echo "[OK]   $param = $value"
            return 0
        fi
    fi
    echo "[SKIP] $param nicht verfügbar"
    return 1
}

# ===================================================================
# 2. SPEICHER-OPTIMIERUNGEN (KRITISCH BEI 1 GB RAM!)
# ===================================================================
echo "[INFO] Setze SPEICHERkritische Optimierungen für 1 GB RAM..."

# vm.swappiness: EXTREM NIEDRIG um Swapping zu vermeiden
# Wert 1: Kernel tausst fast nie aus - bei 1 GB RAM ist Swapping tödlich für Performance
# Swapping verursacht bei Single-CPU massive Einbrüche (10-100x langsamer)
safe_sysctl vm.swappiness 1

# vm.vfs_cache_pressure: Erhöht, um RAM für Anwendungen freizugeben
# Wert 100: Aggressivere Bereinigung von Inode/Dentry Caches
# Bei 1 GB RAM muss Cache-RAM für Anwendungen priorisiert werden
safe_sysctl vm.vfs_cache_pressure 100

# vm.dirty_background_ratio: SEHR NIEDRIG für häufiges Writeback
# Wert 1%: Schreibvorgänge starten bei nur 10MB RAM-Verbrauch
# Verhindert, dass zu viele "dirty pages" RAM blockieren
safe_sysctl vm.dirty_background_ratio 1

# vm.dirty_ratio: NIEDRIG um Prozess-Blockierung zu vermeiden
# Wert 5%: Prozesse blockieren bei 50MB RAM-Verbrauch
# Bei Single-CPU: Blockierte Prozesse = gesamtes System blockiert
safe_sysctl vm.dirty_ratio 5

# vm.dirty_expire_centisecs: KURZ für schnelles Writeback
# 1000 = 10 Sekunden: Dirty pages müssen schnell geschrieben werden
# RAM ist knapp - kann nicht lange für Schreiboperationen blockiert bleiben
safe_sysctl vm.dirty_expire_centisecs 1000

# vm.dirty_writeback_centisecs: HÄUFIG für konstante Writebacks
# 100 = 1 Sekunde: Sehr häufige Prüfungen für gleichmäßige I/O-Last
# Verhindert I/O-Spitzen, die bei Single-CPU besonders problematisch sind
safe_sysctl vm.dirty_writeback_centisecs 100

# ===================================================================
# 3. OVERCOMMIT EINSTELLUNGEN (WICHTIG FÜR 1 GB RAM)
# ===================================================================
echo "[INFO] Setze Memory-Overcommit für limitierten RAM..."

# vm.overcommit_memory: AGRESSIVES Overcommiting
# Wert 1: Immer overcommitten - notwendig für kleine RAM-Systeme
# Erlaubt mehr Prozesse als physikalisch möglich, riskant aber notwendig
safe_sysctl vm.overcommit_memory 1

# vm.overcommit_ratio: Prozent des RAMs der overcommitted werden kann
# Wert 95: Fast das gesamte RAM kann overcommitted werden
safe_sysctl vm.overcommit_ratio 95

# ===================================================================
# 4. NETZWERK-OPTIMIERUNGEN (SINGLE-CPU OPTIMIERT)
# ===================================================================
echo "[INFO] Setze NETZWERKoptimierungen für Single-CPU..."

# net.core.netdev_max_backlog: KLEINER WERT für weniger Kontextwechsel
# 1024: Kleine Queue, um CPU nicht mit Paketverarbeitung zu überlasten
# Single-CPU kann nicht viele Pakete parallel verarbeiten
safe_sysctl net.core.netdev_max_backlog 1024

# net.core.netdev_budget: WENIGER Pakete pro Polling-Zyklus
# 150: Konservativ, um CPU-Zeit für Anwendungen zu erhalten
safe_sysctl net.core.netdev_budget 150

# net.core.netdev_budget_usecs: KURZE Polling-Zeit
# 2000µs = 2ms: Begrenzt CPU-Zeit für Netzwerkverarbeitung
safe_sysctl net.core.netdev_budget_usecs 2000

# net.ipv4.tcp_fin_timeout: SCHNELLER Verbindungsabbau
# 10 Sekunden: Reduziert TIME-WAIT Zustände die RAM belegen
safe_sysctl net.ipv4.tcp_fin_timeout 10

# net.ipv4.tcp_tw_reuse: AKTIVIERT für Socket-Wiederverwendung
# Wichtig bei begrenztem RAM für neue Verbindungen
safe_sysctl net.ipv4.tcp_tw_reuse 1

# net.ipv4.tcp_slow_start_after_idle: DEAKTIVIERT
# Wert 0: TCP bleibt auf voller Geschwindigkeit auch nach Pausen
safe_sysctl net.ipv4.tcp_slow_start_after_idle 0

# TCP Keepalive: KÜRZERE Intervalle für schnelle Verbindungsbereinigung
safe_sysctl net.ipv4.tcp_keepalive_time 180     # 3 Minuten bis erste Probe
safe_sysctl net.ipv4.tcp_keepalive_intvl 15     # 15 Sekunden zwischen Proben
safe_sysctl net.ipv4.tcp_keepalive_probes 3     # Nur 3 Proben

# TCP Buffer: KLEINERE Werte für weniger RAM-Verbrauch
safe_sysctl net.core.rmem_default 65536        # 64KB Default Receive Buffer
safe_sysctl net.core.wmem_default 65536        # 64KB Default Send Buffer
safe_sysctl net.core.rmem_max 1048576          # Max 1MB Receive Buffer
safe_sysctl net.core.wmem_max 1048576          # Max 1MB Send Buffer

# ===================================================================
# 5. SCHEDULER-OPTIMIERUNGEN (SINGLE-CPU SPEZIFISCH)
# ===================================================================
echo "[INFO] Setze SCHEDULERoptimierungen für Single-CPU..."

# kernel.sched_autogroup_enabled: DEAKTIVIERT für weniger Overhead
# Bei Single-CPU bringt Autogroup keine Vorteile, nur Overhead
[ -f /proc/sys/kernel/sched_autogroup_enabled ] && safe_sysctl kernel.sched_autogroup_enabled 0

# kernel.sched_migration_cost_ns: ERHÖHT für weniger Task-Migration
# 10000000 = 10ms: Tasks bleiben länger auf derselben CPU (sinnvoll bei nur 1 CPU)
[ -f /proc/sys/kernel/sched_migration_cost_ns ] && safe_sysctl kernel.sched_migration_cost_ns 10000000

# ===================================================================
# 6. DATEISYSTEM-OPTIMIERUNGEN (MINIMALER RAM)
# ===================================================================
echo "[INFO] Setze DATEISYSTEMoptimierungen für 1 GB RAM..."

# fs.file-max: WENIGER Dateihandles für weniger Kernel-Overhead
# 65536: Ausreichend für kleine Systeme, spart RAM im Kernel
safe_sysctl fs.file-max 65536

# fs.nr_open: Proportional zu file-max
safe_sysctl fs.nr_open 32768

# ===================================================================
# 7. IRQ-HANDLING (ALLES AUF CPU0)
# ===================================================================
echo "[INFO] Konfiguriere IRQ-Handling für Single-CPU..."

# IRQ Balance DEAKTIVIEREN - bei Single-CPU unnötig
if command -v systemctl >/dev/null 2>&1 && systemctl is-active irqbalance >/dev/null 2>&1; then
    echo "[INFO] Deaktiviere irqbalance (Single-CPU)..."
    systemctl stop irqbalance
    systemctl disable irqbalance
fi

# IRQ Affinity manuell auf CPU0 setzen
if [ -d /proc/irq ]; then
    echo "[INFO] Setze alle IRQs auf CPU0..."
    # Verwende find für sichere Dateisuche
    find /proc/irq -name "smp_affinity" -type f 2>/dev/null | while read -r irq; do
        if [ -w "$irq" ]; then
            echo 1 > "$irq" 2>/dev/null && echo "[OK] Setze IRQ Affinity: $irq" || true
        fi
    done
fi

# ===================================================================
# 8. CPU-FREQUENZ GOVERNOR (PERFORMANCE)
# ===================================================================
echo "[INFO] Setze CPU-Governor auf Performance..."

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    echo performance > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
    echo "[OK] CPU0 auf Performance-Governor gesetzt"
fi

# ===================================================================
# 9. OOM-KILLER KONFIGURATION (KRITISCH BEI 1 GB RAM!)
# ===================================================================
echo "[INFO] Konfiguriere OOM-Killer für limitierten RAM..."

# vm.panic_on_oom: KEIN Panic bei OOM - System soll weiterlaufen
safe_sysctl vm.panic_on_oom 0

# vm.oom_kill_allocating_task: Priorisiere aktuellen Task
# Wert 1: Beende den Task, der gerade RAM anfordert - schnellere Reaktion
safe_sysctl vm.oom_kill_allocating_task 1

# ===================================================================
# 10. PERSISTENTE KONFIGURATION
# ===================================================================
echo "[INFO] Erstelle persistente Konfiguration..."
CONFIG_FILE="/etc/sysctl.d/90-openstack-1cpu-1gb.conf"

# Backup
if [ -f "$CONFIG_FILE" ]; then
    BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "[INFO] Backup erstellt: $BACKUP_FILE"
fi

# Konfiguration erstellen
cat > "$CONFIG_FILE" << 'EOF'
# ===================================================================
# OpenStack Performance Tuning – 1 vCPU, 1 GB RAM
# Debian 13 - Generiert: $(date)
# ===================================================================

# SPEICHER-OPTIMIERUNGEN (KRITISCH FÜR 1 GB RAM)
vm.swappiness = 1                    # Minimiert Swapping
vm.vfs_cache_pressure = 100          # Aggressive Cache-Bereinigung
vm.dirty_background_ratio = 1        # Frühes Writeback (bei 10MB)
vm.dirty_ratio = 5                   # Prozess-Blockierung bei 50MB
vm.dirty_expire_centisecs = 1000     # 10 Sekunden bis Writeback
vm.dirty_writeback_centisecs = 100   # Alle 1 Sekunde prüfen

# OVERCOMMIT FÜR KLEINES RAM
vm.overcommit_memory = 1             # Aggressives Overcommitting
vm.overcommit_ratio = 95             # 95% des RAMs overcommitbar

# NETZWERK-OPTIMIERUNGEN (SINGLE-CPU)
net.core.netdev_max_backlog = 1024   # Kleine Queue für Single-CPU
net.core.netdev_budget = 150         # Wenige Pakete pro Zyklus
net.core.netdev_budget_usecs = 2000  # Nur 2ms pro Polling
net.ipv4.tcp_fin_timeout = 10        # Schneller Verbindungsabbau
net.ipv4.tcp_tw_reuse = 1            # Socket-Wiederverwendung
net.ipv4.tcp_slow_start_after_idle = 0 # Kein Slow-Start

# TCP KEEPALIVE (KURZE INTERVALLLE)
net.ipv4.tcp_keepalive_time = 180
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 3

# TCP BUFFER (KLEIN FÜR WENIG RAM)
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.rmem_max = 1048576
net.core.wmem_max = 1048576

# SCHEDULER (SINGLE-CPU OPTIMIERT)
kernel.sched_autogroup_enabled = 0

# DATEISYSTEM (MINIMAL)
fs.file-max = 65536
fs.nr_open = 32768

# OOM-KILLER
vm.panic_on_oom = 0
vm.oom_kill_allocating_task = 1
EOF

# Konfiguration laden
sysctl -p "$CONFIG_FILE" 2>/dev/null || true
echo "[OK] Konfiguration geladen: $CONFIG_FILE"

# ===================================================================
# 11. VERIFIZIERUNG
# ===================================================================
echo "[INFO] Verifiziere kritische Einstellungen..."
echo "================================================================"
echo "SPEICHERKONFIGURATION (1 GB RAM):"
echo "Swappiness: $(cat /proc/sys/vm/swappiness 2>/dev/null || echo 'N/A')"
echo "Dirty Ratio: $(cat /proc/sys/vm/dirty_ratio 2>/dev/null || echo 'N/A')"
echo "Overcommit: $(cat /proc/sys/vm/overcommit_memory 2>/dev/null || echo 'N/A')"
echo ""
echo "NETZWERKKONFIGURATION:"
echo "Backlog: $(cat /proc/sys/net/core/netdev_max_backlog 2>/dev/null || echo 'N/A')"
echo "TCP Fin Timeout: $(cat /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null || echo 'N/A')"
echo ""
echo "SYSTEMSTATUS:"
echo "Verfügbarer RAM: $(free -m | awk '/^Mem:/ {print $4" MB frei"}')"
echo "Swap Nutzung: $(free -m | awk '/^Swap:/ {print $3" MB belegt"}')"

# ===================================================================
# 12. EMPFEHLUNGEN FÜR 1 vCPU / 1 GB RAM
# ===================================================================
echo "================================================================"
echo "[ERFOLG] Optimierung für 1 vCPU / 1 GB RAM abgeschlossen!"
echo ""
echo "KRITISCHE EMPFEHLUNGEN FÜR DIESE KONFIGURATION:"
echo "1. ANWENDUNGSLIMITS SETZEN:"
echo "   • Max. RAM pro Prozess: 256-512 MB"
echo "   • Max. gleichzeitige Verbindungen: 100-200"
echo "   • Worker-Processes/Threads: 1-2"
echo ""
echo "2. MONITORING (regelmäßig prüfen):"
echo "   • RAM: free -h (verfügbaren RAM überwachen)"
echo "   • Swap: swapon -s (Swap-Nutzung vermeiden)"
echo "   • OOM Events: dmesg | grep -i oom"
echo ""
echo "3. WICHTIGSTE PARAMETER FÜR ANWENDUNGEN:"
echo "   • MySQL/PostgreSQL: shared_buffers = 128M"
echo "   • Java: -Xmx256m -Xms128m"
echo "   • PHP-FPM: pm.max_children = 5-10"
echo ""
echo "Konfiguration: $CONFIG_FILE"
echo "Zurücksetzen: rm $CONFIG_FILE && sysctl --system"
echo "================================================================"

exit 0
