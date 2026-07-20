#!/usr/bin/env bash
# DNS for the chroot, AUR helper bootstrap, and the full necessary package list.

copy_resolv_conf() {
  log "Copying resolv.conf into the target (needed for networking inside arch-chroot)..."
  cp /etc/resolv.conf /mnt/etc/resolv.conf
}

bootstrap_yay_and_install() {
  log "Installing base-devel (needed to build yay)..."
  arch-chroot /mnt pacman -S --needed --noconfirm base-devel

  # The user's configured login shell (zsh) isn't installed yet at this
  # point (it's one of the packages installed below), so anything that
  # would launch it (su without an explicit shell, or su -s if /etc/shells
  # doesn't cooperate) can fail. Belt-and-suspenders: make sure /bin/bash
  # is an allowed shell, and use runuser with /bin/bash passed as the
  # literal command to run (not via a "-s shell" override), which sides
  # steps shell-allowlist logic entirely.
  grep -qxF /bin/bash /mnt/etc/shells || echo /bin/bash >> /mnt/etc/shells

  if arch-chroot /mnt command -v yay &>/dev/null; then
    log "yay already installed, skipping bootstrap"
  else
    log "Bootstrapping yay as $USERNAME (makepkg refuses to run as root)..."
    arch-chroot /mnt runuser -u "$USERNAME" -- /bin/bash -c '
      set -e
      cd /tmp
      git clone https://aur.archlinux.org/yay.git
      cd yay
      makepkg -si --noconfirm
    '
  fi

  log "Installing package list: ${PACKAGES[*]}"
  arch-chroot /mnt runuser -u "$USERNAME" -- /bin/bash -c "yay -S --needed --noconfirm ${PACKAGES[*]}"
}
