#!/usr/bin/env bash
# Deploy the plain dotfiles (translated from the NixOS reference's modules)
# into the new user's home directory.

deploy_dotfiles() {
  local home="/mnt/home/$USERNAME"
  local src="$SCRIPT_DIR/dotfiles"

  log "Deploying dotfiles to $home..."

  mkdir -p "$home/.config"
  cp -r "$src/hypr" "$home/.config/"
  cp -r "$src/waybar" "$home/.config/"
  cp -r "$src/kitty" "$home/.config/"
  cp -r "$src/mpv" "$home/.config/"
  cp -r "$src/fastfetch" "$home/.config/"

  cp "$src/zsh/.zshrc" "$home/.zshrc"
  cp "$src/zsh/.p10k.zsh" "$home/.p10k.zsh"

  chmod +x "$home/.config/waybar/scripts/"*.sh

  arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
}
