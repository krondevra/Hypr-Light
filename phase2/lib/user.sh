#!/usr/bin/env bash
# Real user creation and sudo access.

create_user() {
  if arch-chroot /mnt id -u "$USERNAME" &>/dev/null; then
    log "User $USERNAME already exists, skipping useradd"
  else
    log "Creating user $USERNAME..."
    arch-chroot /mnt useradd -m -G wheel,input -s /usr/bin/zsh "$USERNAME"
  fi

  log "Enabling sudo for the wheel group..."
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
  visudo -c -f /mnt/etc/sudoers || die "sudoers file is invalid after edit"

  # Must happen now, not at the end: makepkg (used to bootstrap yay) shells
  # out to sudo, and a freshly useradd'd account has no valid password yet
  # (locked shadow entry), so sudo auth would fail during package install
  # if this were deferred.
  log "Set a password for $USERNAME:"
  arch-chroot /mnt passwd "$USERNAME"
}
