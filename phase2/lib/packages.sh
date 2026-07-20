#!/usr/bin/env bash
# DNS for the chroot, AUR helper bootstrap, and the full necessary package list.

copy_resolv_conf() {
  log "Copying resolv.conf into the target (needed for networking inside arch-chroot)..."
  cp /etc/resolv.conf /mnt/etc/resolv.conf
}

bootstrap_yay_and_install() {
  log "Installing base-devel (needed to build yay)..."
  arch-chroot /mnt pacman -S --needed --noconfirm base-devel

  if arch-chroot /mnt command -v yay &>/dev/null; then
    log "yay already installed, skipping bootstrap"
  else
    log "Bootstrapping yay as $USERNAME (makepkg refuses to run as root)..."
    # -s /bin/bash: the user's configured login shell (zsh) isn't installed
    # yet at this point (it's one of the packages installed below) — using
    # `su -` as-is would try to exec that not-yet-existing shell and fail.
    arch-chroot /mnt su -s /bin/bash -l "$USERNAME" -c '
      set -e
      cd /tmp
      git clone https://aur.archlinux.org/yay.git
      cd yay
      makepkg -si --noconfirm
    '
  fi

  log "Installing package list: ${PACKAGES[*]}"
  arch-chroot /mnt su -s /bin/bash -l "$USERNAME" -c "yay -S --needed --noconfirm ${PACKAGES[*]}"
}
