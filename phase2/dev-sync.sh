#!/usr/bin/env bash
# Dev-loop helper: sync phase2/dotfiles/* onto THIS already-installed system
# (your real $HOME, not /mnt) and restart the affected daemons - for
# iterating on dotfiles/config without a full phase2 reinstall. Run this as
# your normal user (not root) from inside the cloned repo on the VM.
#
# Usage:
#   ./phase2/dev-sync.sh              # sync dotfiles + restart daemons
#   ./phase2/dev-sync.sh --packages   # also yay -S --needed the PACKAGES list
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/dotfiles"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib/common.sh"

[[ "${EUID}" -eq 0 ]] && die "Run as your normal user, not root"

sync_dir() {
  rsync -a --delete "$SRC/$1/" "$HOME/.config/$1/"
}

log "Syncing dotfiles into $HOME..."
sync_dir hypr
sync_dir waybar
sync_dir kitty
sync_dir mpv
sync_dir fastfetch

cp "$SRC/zsh/.zshrc" "$HOME/.zshrc"
cp "$SRC/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

chmod +x "$HOME/.config/waybar/scripts/"*.sh

log "Refreshing hypr-check..."
sed -n "/cat > \/mnt\/usr\/local\/bin\/hypr-check <<'EOF'/,/^EOF$/p" "$SCRIPT_DIR/lib/diagnostics.sh" \
  | sed '1d;$d' \
  | sudo tee /usr/local/bin/hypr-check > /dev/null
sudo chmod +x /usr/local/bin/hypr-check

if [[ "${1:-}" == "--packages" ]]; then
  log "Installing PACKAGES from phase2/install.sh..."
  # Extracts the PACKAGES=( ... ) block verbatim and sources it - depends on
  # install.sh's closing ")" being alone on its own line, same as it is today.
  # shellcheck disable=SC1090
  source <(sed -n '/^PACKAGES=(/,/^)/p' "$SCRIPT_DIR/install.sh")
  yay -S --needed "${PACKAGES[@]}"
fi

log "Restarting waybar/hypridle/hyprpolkitagent..."
pkill waybar 2>/dev/null || true
pkill hypridle 2>/dev/null || true
systemctl --user restart hyprpolkitagent 2>/dev/null || true

waybar >/tmp/waybar.log 2>&1 &
disown
hypridle >/tmp/hypridle.log 2>&1 &
disown

log "Done. Logs: /tmp/waybar.log, /tmp/hypridle.log"
