#!/usr/bin/env bash
# greetd config: autologin straight into Hyprland, same behavior as the
# NixOS reference's greetd.settings.default_session (no interactive greeter).

configure_desktop() {
  log "Writing /etc/greetd/config.toml..."
  mkdir -p /mnt/etc/greetd
  cat > /mnt/etc/greetd/config.toml <<EOF
[terminal]
vt = 1

[default_session]
command = "Hyprland"
user = "$USERNAME"
EOF
  log "Written config:"
  cat /mnt/etc/greetd/config.toml

  log "Verifying greetd and hyprland are actually installed..."
  if arch-chroot /mnt pacman -Q greetd hyprland; then
    log "OK: greetd and hyprland both present"
  else
    warn "greetd or hyprland missing after package install — yay -S likely failed silently for one of them"
  fi

  log "Enabling greetd..."
  arch-chroot /mnt systemctl enable greetd

  # greetd.service is WantedBy=graphical.target, but a plain pacstrap base
  # install defaults to multi-user.target (text mode) — without this,
  # greetd is "enabled" but never actually starts at boot, and you just
  # get a normal getty login on tty1 instead of autologin into Hyprland.
  log "Setting default systemd target to graphical.target..."
  arch-chroot /mnt systemctl set-default graphical.target

  # Belt-and-suspenders: greetd's own unit is supposed to Conflicts=
  # getty@tty1.service, but explicitly disabling it too removes any
  # dependency on that conflict directive actually being present/effective.
  log "Disabling getty@tty1 so it can't race greetd for the console..."
  arch-chroot /mnt systemctl disable getty@tty1.service

  log "Verifying enablement:"
  arch-chroot /mnt systemctl is-enabled greetd || warn "greetd is not enabled — see output above"
  arch-chroot /mnt systemctl get-default || warn "systemctl get-default failed"
}
