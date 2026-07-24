#!/usr/bin/env bash
# Installs a system-wide `hypr-check` command: a manual health check to run
# once logged into Hyprland, surfacing the errors most likely to explain
# "something's wrong" - Hyprland config parse errors, failed systemd units,
# and error-level journal lines from the current boot.

install_diagnostics() {
  log "Installing hypr-check diagnostic script..."
  cat > /mnt/usr/local/bin/hypr-check <<'EOF'
#!/usr/bin/env bash
# Manual post-login health check. Run from inside a Hyprland session.
set -uo pipefail

section() { printf '\n==== %s ====\n' "$1"; }

section "Hyprland config errors"
if command -v hyprctl >/dev/null 2>&1; then
  errors="$(hyprctl configerrors 2>&1)"
  if [[ -z "$errors" || "$errors" == "ok" ]]; then
    echo "none"
  else
    echo "$errors"
  fi
else
  echo "hyprctl not found - not running inside a Hyprland session?"
fi

section "Failed systemd units"
failed="$(systemctl --failed --no-legend)"
[[ -z "$failed" ]] && echo "none" || echo "$failed"

section "Journal errors (priority=err, this boot)"
journalctl -p 3 -b --no-pager || echo "journalctl failed"

section "greetd log (this boot)"
journalctl -u greetd -b --no-pager || echo "no greetd log for this boot"

section "waybar log (filtered, this boot)"
if [[ -f /tmp/waybar.log ]]; then
  grep -iE 'warning|error|bar configured' /tmp/waybar.log || echo "no warnings/errors found"
else
  echo "/tmp/waybar.log not found - run phase2/dev-sync.sh or redirect waybar's output there"
fi

section "hypridle log (filtered, this boot)"
if [[ -f /tmp/hypridle.log ]]; then
  grep -iE 'warning|error|inhibited sleep|releasing the sleep|registered timeout|wayland session' /tmp/hypridle.log \
    | grep -v -iE 'got iface|bound to' || echo "no warnings/errors found"
else
  echo "/tmp/hypridle.log not found"
fi
EOF
  chmod +x /mnt/usr/local/bin/hypr-check
}
