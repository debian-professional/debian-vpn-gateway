#!/bin/bash
# ============================================
# OpenStack / KVM Performance Tuning – 1 vCPU
# Debian 13
# ============================================

set -e

echo "[INFO] Applying 1 vCPU tuning profile"

# -------------------------
# Scheduler
# -------------------------
sysctl -w kernel.sched_autogroup_enabled=0
sysctl -w kernel.sched_migration_cost_ns=5000000

# -------------------------
# Memory
# -------------------------
sysctl -w vm.swappiness=5
sysctl -w vm.vfs_cache_pressure=50

# IO writeback – ruhig & gleichmäßig
sysctl -w vm.dirty_background_ratio=5
sysctl -w vm.dirty_ratio=10

# -------------------------
# Network (single CPU safe)
# -------------------------
sysctl -w net.core.netdev_max_backlog=2048
sysctl -w net.core.netdev_budget=300
sysctl -w net.core.netdev_budget_usecs=8000

sysctl -w net.ipv4.tcp_fin_timeout=20
sysctl -w net.ipv4.tcp_tw_reuse=1
sysctl -w net.ipv4.tcp_mtu_probing=1

# -------------------------
# IRQ handling
# -------------------------
# Alles bleibt auf CPU0 – KEIN Pinning nötig
for irq in /proc/irq/*/smp_affinity_list; do
  echo 0 > "$irq" 2>/dev/null || true
done

echo "[OK] 1 vCPU tuning applied successfully"
