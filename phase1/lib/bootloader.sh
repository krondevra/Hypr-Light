#!/usr/bin/env bash
# Base system settings (hostname/timezone/locale) and bootloader install,
# both applied via arch-chroot into the freshly pacstrapped target.

configure_base_system() {
  log "Setting hostname/timezone/locale..."
  arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
  arch-chroot /mnt hwclock --systohc
  echo "$LOCALE UTF-8" >> /mnt/etc/locale.gen
  arch-chroot /mnt locale-gen
  echo "LANG=$LOCALE" > /mnt/etc/locale.conf
  echo "$HOSTNAME" > /mnt/etc/hostname
  cat > /mnt/etc/hosts <<EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	$HOSTNAME.localdomain	$HOSTNAME
EOF

  arch-chroot /mnt systemctl enable NetworkManager
}

configure_luks_boot() {
  log "Wiring LUKS into the initramfs and bootloader..."

  local root_uuid
  root_uuid="$(blkid -s UUID -o value "$ROOT_PART")"

  # mkinitcpio's hook name (and the matching kernel parameter) differs
  # depending on whether the default HOOKS array is the classic udev-based
  # family or the newer systemd-based family. Detect which one is active
  # instead of assuming, so this works regardless of which default the
  # installed mkinitcpio.conf ships with.
  local hooks_line luks_kernel_param
  hooks_line="$(grep '^HOOKS=' /mnt/etc/mkinitcpio.conf)"
  if [[ "$hooks_line" =~ (^|[[:space:](])systemd([[:space:])]|$) ]]; then
    log "systemd-based initramfs detected — using sd-encrypt hook"
    sed -i '/^HOOKS=/ s/\bfilesystems\b/sd-encrypt filesystems/' /mnt/etc/mkinitcpio.conf
    luks_kernel_param="rd.luks.name=${root_uuid}=cryptroot"
  else
    log "udev-based initramfs detected — using encrypt hook"
    sed -i '/^HOOKS=/ s/\bfilesystems\b/encrypt filesystems/' /mnt/etc/mkinitcpio.conf
    luks_kernel_param="cryptdevice=UUID=${root_uuid}:cryptroot"
  fi

  arch-chroot /mnt mkinitcpio -P

  log "Verifying cryptsetup is present in the built initramfs..."
  if arch-chroot /mnt lsinitcpio /boot/initramfs-linux.img 2>/dev/null | grep -q cryptsetup; then
    log "OK: cryptsetup found in initramfs-linux.img"
  else
    warn "cryptsetup NOT found in initramfs-linux.img — LUKS unlock will fail at boot"
  fi

  # GRUB itself needs cryptodisk support enabled, and the kernel command
  # line needs to know which partition to unlock and which btrfs subvolume
  # to mount as root before mounting root.
  if grep -q '^GRUB_ENABLE_CRYPTODISK=' /mnt/etc/default/grub; then
    sed -i 's/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' /mnt/etc/default/grub
  elif grep -q '^#GRUB_ENABLE_CRYPTODISK=' /mnt/etc/default/grub; then
    sed -i 's/^#GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' /mnt/etc/default/grub
  else
    echo 'GRUB_ENABLE_CRYPTODISK=y' >> /mnt/etc/default/grub
  fi

  sed -i "s|^GRUB_CMDLINE_LINUX=\"|GRUB_CMDLINE_LINUX=\"${luks_kernel_param} rootflags=subvol=@ |" /mnt/etc/default/grub
  log "Final GRUB_CMDLINE_LINUX: $(grep '^GRUB_CMDLINE_LINUX=' /mnt/etc/default/grub)"
}

install_bootloader() {
  log "Installing bootloader ($BOOT_MODE)..."
  if [[ "$BOOT_MODE" == "uefi" ]]; then
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  else
    arch-chroot /mnt grub-install --target=i386-pc "$DISK"
  fi
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}
