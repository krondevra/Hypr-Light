#!/usr/bin/env bash
# Laptop-hardware services. pipewire/wireplumber self-activate via socket
# units on package install, nothing to enable there.

enable_services() {
  log "Enabling power-profiles-daemon, iio-sensor-proxy, and bluetooth..."
  arch-chroot /mnt systemctl enable power-profiles-daemon iio-sensor-proxy bluetooth
}
