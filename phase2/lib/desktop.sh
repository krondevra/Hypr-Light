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

  log "Enabling greetd..."
  arch-chroot /mnt systemctl enable greetd

  # greetd.service is WantedBy=graphical.target, but a plain pacstrap base
  # install defaults to multi-user.target (text mode) — without this,
  # greetd is "enabled" but never actually starts at boot, and you just
  # get a normal getty login on tty1 instead of autologin into Hyprland.
  log "Setting default systemd target to graphical.target..."
  arch-chroot /mnt systemctl set-default graphical.target
}
