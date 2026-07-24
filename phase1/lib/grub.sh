#!/usr/bin/env bash
# Console-rotation and boot-speed tweaks for the rotated panel: zero GRUB
# timeout and fbcon=rotate:1 on the default boot entry only (recovery
# entries untouched). Kept separate from bootloader.sh since it edits a
# different GRUB_CMDLINE_* variable than configure_luks_boot
# (GRUB_CMDLINE_LINUX_DEFAULT vs GRUB_CMDLINE_LINUX) and is unconditional
# hardware-specific config, not part of the LUKS/boot-mode logic.

configure_grub_extras() {
  log "Setting GRUB_TIMEOUT=0 and enabling console rotation (fbcon=rotate:1)..."

  if grep -q '^GRUB_TIMEOUT=' /mnt/etc/default/grub; then
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /mnt/etc/default/grub
  elif grep -q '^#GRUB_TIMEOUT=' /mnt/etc/default/grub; then
    sed -i 's/^#GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /mnt/etc/default/grub
  else
    echo 'GRUB_TIMEOUT=0' >> /mnt/etc/default/grub
  fi

  if grep -q 'fbcon=rotate:1' /mnt/etc/default/grub; then
    log "fbcon=rotate:1 already present in GRUB_CMDLINE_LINUX_DEFAULT, skipping"
  else
    sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT="|GRUB_CMDLINE_LINUX_DEFAULT="fbcon=rotate:1 |' /mnt/etc/default/grub
  fi

  log "Final GRUB_TIMEOUT: $(grep '^GRUB_TIMEOUT=' /mnt/etc/default/grub)"
  log "Final GRUB_CMDLINE_LINUX_DEFAULT: $(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /mnt/etc/default/grub)"
}
