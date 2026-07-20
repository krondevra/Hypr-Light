#!/usr/bin/env bash
# Cleanup of any previous attempt, then GPT partitioning.

cleanup_previous() {
  log "Cleanup previous attempt..."
  umount -R /mnt 2>/dev/null || true
  swapoff -a 2>/dev/null || true
  cryptsetup close cryptroot 2>/dev/null || true
  mkdir -p /mnt
}

partition_disk() {
  log "Partitioning $DISK..."
  parted -s "$DISK" mklabel gpt

  if [[ "$BOOT_MODE" == "bios" ]]; then
    parted -s "$DISK" mkpart biosboot 1MiB 3MiB
    parted -s "$DISK" set 1 bios_grub on
    parted -s "$DISK" mkpart ESP fat32 3MiB 515MiB
    parted -s "$DISK" set 2 esp on
    parted -s "$DISK" mkpart primary 515MiB 100%
  else
    parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
    parted -s "$DISK" set 1 esp on
    parted -s "$DISK" mkpart primary 513MiB 100%
  fi
}
