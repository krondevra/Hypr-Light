#!/usr/bin/env bash
# Base system install (pacstrap) and fstab generation.

run_pacstrap() {
  local packages=("${BASE_PACKAGES[@]}")
  if [[ "$BOOT_MODE" == "uefi" ]]; then
    packages+=(efibootmgr)
  fi

  log "Running pacstrap: ${packages[*]}"
  pacstrap /mnt "${packages[@]}"

  log "Generating fstab..."
  genfstab -U /mnt >> /mnt/etc/fstab
}
