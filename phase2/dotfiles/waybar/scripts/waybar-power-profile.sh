#!/bin/bash
# Displays the current power-profiles-daemon profile as a Waybar module,
# and cycles to the next one when called with --cycle (bind this to on-click).
set -euo pipefail

PROFILES=(power-saver balanced performance)
ICONS=("󰾆" "󰾅" "󰓅")

current="$(powerprofilesctl get)"

cycle() {
    for i in "${!PROFILES[@]}"; do
        if [[ "${PROFILES[$i]}" == "$current" ]]; then
            next=$(( (i + 1) % ${#PROFILES[@]} ))
            powerprofilesctl set "${PROFILES[$next]}"
            return
        fi
    done
    powerprofilesctl set balanced
}

if [[ "${1:-}" == "--cycle" ]]; then
    cycle
    exit 0
fi

for i in "${!PROFILES[@]}"; do
    if [[ "${PROFILES[$i]}" == "$current" ]]; then
        echo "{\"text\": \"${ICONS[$i]} ${current}\", \"tooltip\": \"Click to cycle power profile\"}"
        exit 0
    fi
done

echo "{\"text\": \"? ${current}\", \"tooltip\": \"Unrecognized profile\"}"
