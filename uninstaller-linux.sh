#!/bin/bash

set -e

# Functions
stop_sentinel_service() {
  echo "Stopping Sentinel service..."
  systemctl stop sentinelone.service || true
}

disable_sentinel_service() {
  echo "Disabling Sentinel service..."
  systemctl disable sentinelone.service || true
}

delete_sentinel_directories() {
  echo "Deleting Sentinel service files..."
  rm -rf /usr/lib/systemd/system/sentinelone.service /lib/systemd/system/sentinelone.service || true
}

reload_services() {
  echo "Reloading services..."
  systemctl daemon-reload || true
  systemctl reset-failed || true
}

kill_sentinel_processes() {
  echo "Killing Sentinel processes..."
  ps aux | grep 's1-\|sentinelone-watchdog' | awk '{print $2}' | xargs kill -9 2>/dev/null || true
}

unmount_directories() {
  echo "Unmounting Sentinel directories..."
  umount -l /opt/sentinelone/ebpfs/bpf_mount || true
  umount -l /opt/sentinelone/mount || true
  umount -l /opt/sentinelone/cgroups/memory || true
  umount -l /opt/sentinelone/rpm_mount || true
}

delete_sentinel_directories_final() {
  echo "Deleting remaining Sentinel directories..."
  rm -rf /opt/sentinelone || true
}

delete_sentinel_user() {
  echo "Deleting Sentinel user..."
  userdel -f sentinelone || true
}

uninstall_sentinel_components() {
  echo "Uninstalling Sentinel components..."
  rpm -ev --noscripts SentinelAgent 2>/dev/null || true
}

# Main logic
stop_sentinel_service
disable_sentinel_service
delete_sentinel_directories
reload_services
kill_sentinel_processes
unmount_directories
delete_sentinel_directories_final
delete_sentinel_user
uninstall_sentinel_components

echo "Sentinel has been successfully uninstalled."
