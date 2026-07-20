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

install_bootloader() {
  log "Installing bootloader ($BOOT_MODE)..."
  if [[ "$BOOT_MODE" == "uefi" ]]; then
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  else
    arch-chroot /mnt grub-install --target=i386-pc "$DISK"
  fi
  arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}
