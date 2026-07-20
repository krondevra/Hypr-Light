#!/usr/bin/env bash
# Filesystems: fat32 ESP, btrfs root with @/@home subvolumes, zstd compression.

setup_filesystems() {
  log "Formatting filesystems..."
  mkfs.fat -F32 "$EFI_PART"
  mkfs.btrfs -f /dev/mapper/cryptroot

  log "Creating btrfs subvolumes..."
  mount /dev/mapper/cryptroot /mnt
  btrfs subvolume create /mnt/@
  btrfs subvolume create /mnt/@home
  umount /mnt

  log "Mounting..."
  mount -o subvol=@,compress=zstd /dev/mapper/cryptroot /mnt
  mkdir -p /mnt/boot /mnt/home
  mount -o subvol=@home,compress=zstd /dev/mapper/cryptroot /mnt/home
  mount "$EFI_PART" /mnt/boot
}
