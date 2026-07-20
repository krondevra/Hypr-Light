#!/usr/bin/env bash
# LUKS encryption of the root partition.

setup_luks() {
  log "Encrypting $ROOT_PART..."
  cryptsetup luksFormat "$ROOT_PART"
  cryptsetup open "$ROOT_PART" cryptroot
}
