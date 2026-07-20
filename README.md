# Hypr-Light

A from-scratch Arch Linux setup: boot the vanilla Arch ISO, `git clone` this repo, run one
script — no `archinstall`. Split into two phases:

1. **Phase 1 — install** (`phase1/`): partition, encrypt, format, mount, `pacstrap` the base
   system, install the bootloader. Ends with a bootable, unconfigured base Arch system.
2. **Phase 2 — post-configuration**: packages, Hyprland, services, dotfiles, user setup.
   **Not started yet.**

## Requirements

- Booted from the official Arch ISO.
- Network already up (DHCP is automatic in a VM with a virtio/e1000 NIC; use `iwctl` first
  if you're on wifi).
- Running as root (default on the ISO).

## Usage

```sh
git clone https://github.com/krondevra/Hypr-Light.git
cd Hypr-Light/phase1
./install.sh
```

The script lists disks, prompts for the target disk, and requires typing `YES` to confirm
before doing anything destructive. Everything after that (partitioning, encryption,
formatting, `pacstrap`, bootloader install) is automatic.

Hostname, timezone, and locale are hardcoded constants at the top of `phase1/install.sh` —
edit them there before running if the defaults (`hypr-light`, `Europe/Riga`, `en_US.UTF-8`)
don't fit.

## Disk layout

GPT, LUKS-encrypted root, btrfs with `@` and `@home` subvolumes (`zstd` compression). Same
scheme on UEFI and BIOS, with an extra `bios_grub` partition added on BIOS systems.

## Repo structure

```
phase1/
├── install.sh       # entrypoint — sources lib/*.sh, runs the install in order
└── lib/
    ├── common.sh     # logging, require_root, confirm()
    ├── disk.sh       # boot-mode detect, disk listing/prompt, partition-name computation
    ├── partition.sh  # cleanup of previous attempts, parted GPT partitioning
    ├── luks.sh       # LUKS format + open
    ├── filesystem.sh # mkfs.fat32/btrfs, @/@home subvolumes, mount
    ├── pacstrap.sh   # pacstrap + genfstab
    └── bootloader.sh # hostname/timezone/locale, grub install (UEFI/BIOS)
```

Each `lib/*.sh` file only defines functions; `install.sh` is the single place that decides
the order they run in.

## Testing

This is developed and tested in a VM, not on the host: boot the Arch ISO in a VM, `git clone`
this repo from inside the guest, and run `phase1/install.sh` there. The repo is private, so
cloning from inside the ISO needs a GitHub personal access token (no `gh` auth is available
on the live ISO) — either embed it in the clone URL or enter it as the password when
prompted.

## Status

- Phase 1: implemented, not yet run end-to-end in a VM.
- Phase 2: not started.
