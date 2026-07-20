#!/usr/bin/env bash
# Boot-mode detection, disk selection, and partition-name computation.

detect_boot_mode() {
  if [[ -d /sys/firmware/efi ]]; then
    BOOT_MODE="uefi"
  else
    BOOT_MODE="bios"
  fi
  log "Boot mode detected: $BOOT_MODE"
}

list_disks() {
  log "Available disks:"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
  echo
}

prompt_disk() {
  read -rp "Enter target disk (example: vda, /dev/vda, sda, /dev/sda, nvme0n1): " DISK

  if [[ "$DISK" != /dev/* ]]; then
    DISK="/dev/$DISK"
  fi

  if [[ ! -b "$DISK" ]]; then
    die "disk $DISK does not exist."
  fi
}

compute_partition_names() {
  if [[ "$BOOT_MODE" == "bios" ]]; then
    if [[ "$DISK" =~ (nvme|mmcblk) ]]; then
      BIOS_PART="${DISK}p1"
      EFI_PART="${DISK}p2"
      ROOT_PART="${DISK}p3"
    else
      BIOS_PART="${DISK}1"
      EFI_PART="${DISK}2"
      ROOT_PART="${DISK}3"
    fi
  else
    BIOS_PART=""
    if [[ "$DISK" =~ (nvme|mmcblk) ]]; then
      EFI_PART="${DISK}p1"
      ROOT_PART="${DISK}p2"
    else
      EFI_PART="${DISK}1"
      ROOT_PART="${DISK}2"
    fi
  fi
}

confirm_destructive() {
  echo
  log "Target disk: $DISK"
  if [[ "$BOOT_MODE" == "bios" ]]; then
    log "BIOS boot partition: $BIOS_PART"
  fi
  log "EFI partition: $EFI_PART"
  log "Root/LUKS partition: $ROOT_PART"

  confirm "ALL DATA ON $DISK WILL BE ERASED. Type YES to continue: " || die "Aborted."
}
