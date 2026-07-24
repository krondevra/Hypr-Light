# Hypr-Light

A from-scratch Arch Linux setup: boot the vanilla Arch ISO, `git clone` this repo, run one
script — no `archinstall`. Split into two phases:

1. **Phase 1 — install** (`phase1/`): partition, encrypt, format, mount, `pacstrap` the base
   system, install the bootloader. Ends with a bootable, unconfigured base Arch system.
2. **Phase 2 — post-configuration** (`phase2/`): creates the real user, installs the
   necessary package list, configures greetd/Hyprland autologin, enables laptop-hardware
   services, deploys dotfiles. Runs automatically at the end of phase 1 (same ISO session,
   before reboot), and is also independently re-runnable on its own.

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
formatting, `pacstrap`, bootloader install, then phase 2) is automatic, aside from two
password prompts (root, then the new user).

Hostname, timezone, and locale are hardcoded constants at the top of `phase1/install.sh` —
edit them there before running if the defaults (`hypr-light`, `Europe/Riga`, `en_US.UTF-8`)
don't fit. The username and package list are hardcoded constants at the top of
`phase2/install.sh` (default username: `user`).

## Disk layout

GPT, LUKS-encrypted root, btrfs with `@` and `@home` subvolumes (`zstd` compression). Same
scheme on UEFI and BIOS, with an extra `bios_grub` partition added on BIOS systems.

## Console rotation

This build targets a specific rotated-panel device (a GPD Pocket-style machine with a
1600x2560 portrait panel). `phase1/lib/grub.sh` unconditionally sets `GRUB_TIMEOUT=0` and
appends `fbcon=rotate:1` to `GRUB_CMDLINE_LINUX_DEFAULT` in the target's `/etc/default/grub`,
so the text-mode console framebuffer is pre-rotated to match the panel before Hyprland's own
`monitor=...,transform,3` (`phase2/dotfiles/hypr/hyprland.conf`) takes over post-login. If
you're installing on non-rotated hardware, drop the `configure_grub_extras` call in
`phase1/install.sh` before running.

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
    ├── bootloader.sh # hostname/timezone/locale, LUKS-aware initramfs, grub install (UEFI/BIOS)
    └── grub.sh       # GRUB_TIMEOUT=0 + fbcon=rotate:1 rotated-panel console tweak

phase2/
├── install.sh       # entrypoint — USERNAME + package list constants, sources lib/*.sh
├── lib/
│   ├── common.sh     # logging, require_root
│   ├── user.sh       # useradd (wheel, zsh shell), sudoers, sets the user's password
│   ├── packages.sh   # resolv.conf into /mnt, bootstrap yay, install the package list
│   ├── desktop.sh    # /etc/greetd/config.toml (autologin into Hyprland), enable greetd
│   ├── services.sh   # enable power-profiles-daemon, iio-sensor-proxy
│   ├── dotfiles.sh   # copy dotfiles/* into the new user's home, chown
│   └── diagnostics.sh # installs `hypr-check`, a manual post-login health check
└── dotfiles/         # plain Hyprland/waybar/kitty/mpv/fastfetch/zsh configs
```

Each `lib/*.sh` file only defines functions; each phase's `install.sh` is the single place
that decides the order they run in.

## Packages

Phase 2 installs only what's necessary for a working Hyprland session — core desktop tools,
the Hyprland/greetd/portal/pipewire stack (with Qt-on-Wayland compatibility), idle/lock/polkit
session essentials, fonts, the zsh+powerlevel10k shell, and a handful of laptop-hardware and
system utilities (brightness, sensors, USB info, sync, JSON, exFAT) — via a single
`yay -S --needed` call (yay is bootstrapped first, and handles official-repo and AUR packages
uniformly so nothing has to be pre-classified). Still "necessary only", not "nice to have":
these are session-readiness packages, not full applications — no editors, office suite,
media/creative apps, virtualization stack, or Waydroid — see the constants block at the top
of `phase2/install.sh` for the exact list.

## Diagnostics

Phase 2 installs `hypr-check`, a system-wide command for a quick health check after logging
into Hyprland: Hyprland config parse errors (`hyprctl configerrors`), failed systemd units,
error-priority journal lines from the current boot, and the greetd log. Run it manually from
a terminal inside the session — it's not wired to run automatically.

## Testing

This is developed and tested in a VM, not on the host: boot the Arch ISO in a VM, `git clone`
this repo from inside the guest, and run `phase1/install.sh` there. The repo is public, so
cloning from inside the ISO needs no authentication.

## Status

- Phase 1: implemented and proven end-to-end in a VM (partition/LUKS/pacstrap/boot all
  confirmed working, including the LUKS passphrase prompt at boot).
- Phase 2: implemented and confirmed in a VM — clean `hyprctl configerrors` (via `hypr-check`),
  console rotation and `start-hyprland` launch both confirmed on real rotated-panel hardware,
  and the expanded session-package list installs cleanly.
- `hypridle`/`hyprlock`/`hyprpolkitagent` are now wired into `hyprland.conf` via `exec-once`
  (idle-timeout lock/DPMS and the polkit agent). Not yet re-tested in a VM since this wiring
  was added.
