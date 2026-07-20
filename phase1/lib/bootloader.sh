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

  # mkinitcpio needs the encrypt hook to prompt for the passphrase at boot;
  # insert it right before the filesystems hook regardless of the rest of
  # the default HOOKS array.
  sed -i 's/\bfilesystems\b/encrypt filesystems/' /mnt/etc/mkinitcpio.conf
  arch-chroot /mnt mkinitcpio -P

  # GRUB itself needs cryptodisk support enabled, and the kernel command
  # line needs to know which partition to unlock before mounting root.
  if grep -q '^GRUB_ENABLE_CRYPTODISK=' /mnt/etc/default/grub; then
    sed -i 's/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' /mnt/etc/default/grub
  elif grep -q '^#GRUB_ENABLE_CRYPTODISK=' /mnt/etc/default/grub; then
    sed -i 's/^#GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' /mnt/etc/default/grub
  else
    echo 'GRUB_ENABLE_CRYPTODISK=y' >> /mnt/etc/default/grub
  fi

  local root_uuid
  root_uuid="$(blkid -s UUID -o value "$ROOT_PART")"
  sed -i "s|^GRUB_CMDLINE_LINUX=\"|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${root_uuid}:cryptroot |" /mnt/etc/default/grub
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
