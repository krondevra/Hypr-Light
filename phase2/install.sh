#!/usr/bin/env bash
# Phase 2: post-configuration. Assumes /mnt is already mounted and
# pacstrapped by phase 1 (run via arch-chroot into that target).
# Creates the real user, installs the necessary package list, configures
# greetd/Hyprland autologin, enables laptop-hardware services, and deploys
# dotfiles. Independently runnable/re-runnable on its own for VM iteration.
set -euo pipefail

# --- constants (edit these to taste) ---
USERNAME="user"
PACKAGES=(
  # core desktop (packages.nix)
  curl dunst fastfetch firefox git grim hyprpaper kitty pavucontrol slurp
  swayimg tree neovim yazi waybar wget wl-clipboard wofi
  network-manager-applet blueman
  # desktop stack (desktop-hyprland.nix / sound.nix / implicit program installs)
  hyprland greetd xdg-desktop-portal xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk polkit dbus pipewire pipewire-pulse wireplumber
  rtkit mpv qt5-wayland qt6-wayland
  # session essentials (idle/lock/polkit) - packages only; exec-once wiring
  # into hyprland.conf is a follow-up, see .tmp/notes/initial-setup-analysis.md
  hypridle hyprlock hyprpolkitagent
  # fonts
  ttf-jetbrains-mono-nerd
  # shell
  zsh zsh-autosuggestions zsh-syntax-highlighting zsh-theme-powerlevel10k
  # laptop-hardware services + utilities
  power-profiles-daemon iio-sensor-proxy brightnessctl lm_sensors
  # system utilities
  usbutils rsync jq exfatprogs
  # NPU status widget (waybar custom/npu)
  xrt xrt-plugin-amdxdna
)
# ----------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

for module in common user packages desktop services dotfiles diagnostics; do
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/lib/$module.sh"
done

require_root
mountpoint -q /mnt || die "/mnt is not mounted — run phase 1 first (or re-mount it)"

copy_resolv_conf
create_user
bootstrap_yay_and_install
configure_desktop
enable_services
deploy_dotfiles
install_diagnostics

log "Phase 2 done. Reboot into your new system."
