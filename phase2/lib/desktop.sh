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
}
