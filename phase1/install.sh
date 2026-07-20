#!/usr/bin/env bash
# Phase 1: partition, encrypt, format, mount, pacstrap, install bootloader.
# Run from a booted Arch ISO. Ends with a bootable, unconfigured base system
# (no desktop, no extra user) — phase 2 handles the rest, separately.
set -euo pipefail

# --- constants (edit these to taste) ---
HOSTNAME="hypr-light"
TIMEZONE="Europe/Riga"
LOCALE="en_US.UTF-8"
BASE_PACKAGES=(base linux linux-firmware btrfs-progs cryptsetup grub networkmanager sudo git vim)
# ----------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for module in common disk partition luks filesystem pacstrap bootloader; do
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/lib/$module.sh"
done

require_root

detect_boot_mode
list_disks
prompt_disk
compute_partition_names
confirm_destructive

cleanup_previous
partition_disk
setup_luks
setup_filesystems
run_pacstrap
configure_base_system
configure_luks_boot
install_bootloader

arch-chroot /mnt passwd

log "Done. Remove installer media, then reboot."
