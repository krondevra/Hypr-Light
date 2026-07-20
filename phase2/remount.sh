#!/usr/bin/env bash
# Re-mount an already phase1-completed disk at /mnt (non-destructive), so
# phase2/install.sh can be re-run standalone without redoing phase 1's
# partition/format wipe. Run this from a booted Arch ISO.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PHASE1_LIB="$SCRIPT_DIR/../phase1/lib"

# shellcheck source=/dev/null
source "$PHASE1_LIB/common.sh"
# shellcheck source=/dev/null
source "$PHASE1_LIB/disk.sh"

require_root

detect_boot_mode
list_disks
prompt_disk
compute_partition_names

log "Opening LUKS container on $ROOT_PART (enter the passphrase you set during phase 1)..."
cryptsetup open "$ROOT_PART" cryptroot

log "Mounting..."
mount -o subvol=@,compress=zstd /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot /mnt/home
mount -o subvol=@home,compress=zstd /dev/mapper/cryptroot /mnt/home
mount "$EFI_PART" /mnt/boot

log "Mounted. You can now run ../phase2/install.sh directly."
