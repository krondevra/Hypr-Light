#!/usr/bin/env bash
# Shared logging/guard helpers used by every phase 1 module.

log() {
  echo "[*] $*"
}

warn() {
  echo "[!] $*" >&2
}

die() {
  echo "[x] $*" >&2
  exit 1
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "Run as root"
  fi
}

confirm() {
  local prompt="$1"
  local reply
  read -rp "$prompt" reply
  [[ "$reply" == "YES" ]]
}
