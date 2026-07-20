#!/usr/bin/env bash
# Shared logging/guard helpers used by every phase 2 module.
# Own copy (not sourced from phase1/) so phase2 stays independently runnable.

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
