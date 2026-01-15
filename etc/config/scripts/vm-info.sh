#!/bin/bash
# Debian 13 – OpenStack VM Performance Info Collector
# Read-only, safe, root recommended

set -u

echo "============================================"
echo " OpenStack VM Performance Information"
echo "============================================"
echo

# Basic system info
echo "[SYSTEM]"
hostnamectl
echo

# Hypervisor detection
echo "[VIRTUALIZATION]"
systemd-detect-virt
echo

# CPU information
echo "[CPU]"
lscpu
echo

echo "[CPU GOVERNOR]"
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$cpu" ] && echo "$cpu: $(cat "$cpu")"
done
echo

# NUMA information
echo "[NUMA]"
if command -v numactl >/dev/null; then
    numactl --hardware
else
    echo "numactl not installed"
fi
echo

# IRQ balance
echo "[IRQBALANCE]"
if systemctl list-unit-files | grep -q irqbalance; then
    systemctl status irqbalance --no-pager
else
    echo "irqbalance not installed"
fi
echo

# Interrupts overview
echo "[INTERRUPTS – virtio related]"
grep -i virtio /proc/interrupts || echo "No virtio IRQs found"
echo

# Network interfaces
echo "[NETWORK INTERFACES]"
ip -brief link
echo

for iface in $(ls /sys/class/net | grep -v lo); do
    echo "Interface: $iface"
    ethtool -k "$iface" 2>/dev/null | grep -E \
        "tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload" \
        || echo "  Offload info unavailable"
    ethtool -l "$iface" 2>/dev/null || echo "  No multiqueue info"
    echo
done

# Storage devices
echo "[BLOCK DEVICES]"
lsblk -o NAME,TYPE,MODEL,SCHED,ROTA
echo

for dev in /sys/block/vd*; do
    [ -d "$dev" ] || continue
    echo "Device: $(basename "$dev")"
    cat "$dev/queue/scheduler" 2>/dev/null
    cat "$dev/queue/nr_requests" 2>/dev/null
    echo
done

# Sysctl snapshot (relevant only)
echo "[SYSCTL – PERFORMANCE RELEVANT]"
SYSCTL_REGEX='kernel.sched|vm.swappiness|vm.dirty|net.core.(rmem|wmem|netdev)|net.ipv4.tcp_'
sysctl -a 2>/dev/null | grep -E "$SYSCTL_REGEX" | sort
echo

# Load & context switches
echo "[LOAD & CONTEXT SWITCHES]"
uptime
vmstat 1 3
echo

echo "============================================"
echo " Collection complete"
echo "============================================"
