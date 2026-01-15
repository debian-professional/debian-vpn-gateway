#!/bin/bash
# ==================================================
# OpenStack / KVM Performance Tuning – 2 vCPU
# Debian 13 (trixie)
# ==================================================

set -e

echo "[INFO] Applying OpenStack 2 vCPU tuning profile"

# --------------------------------------------------
# Scheduler
# --------------------------------------------------
# Verhindert unnötige Task-Gruppierung
sysctl -w kernel.sched_autogroup_enabled=0

# Tasks sollen länger auf derselben CPU bleiben
sysctl -w kernel.sched_migration_cost_ns=5000000

# --------------------------------------------------
# Memory
# --------------------------------------------------
# Swap vermeiden (Cloud-Standard)
sysctl -w vm.swappiness=10

# Cache sinnvoll halten
sysctl -w vm.vfs_cache_pressure=50

# Gleichmäßiges Writeback (VirtIO-freundlich)
sysctl -w vm.dirty_background_ratio=5
sysctl -w vm.dirty_ratio=15

# --------------------------------------------------
# Network (2 vCPU optimiert)
# --------------------------------------------------
sysctl -w net.core.netdev_max_backlog=4096
sysctl -w net.core.netdev_budget=600
sysctl -w net.core.netdev_budget_usecs=12000

# TCP sinnvoll aggressiver
sysctl -w net.ipv4.tcp_fin_timeout=15
sysctl -w net.ipv4.tcp_tw_reuse=1
sysctl -w net.ipv4.tcp_mtu_probing=1

#
