#!/bin/bash
# Cycles the power-profiles-daemon profile when called with --cycle (bound
# to waybar's battery module on-click, since battery replaced the standalone
# power-profile widget). Run with no args to print the current profile as a
# waybar custom-module JSON blob, kept for standalone/manual use.
set -euo pipefail

PROFILES=(power-saver balanced performance)
ICONS=("󰾆" "󰾅" "󰓅")

current="$(powerprofilesctl get)"

cycle() {
    for i in "${!PROFILES[@]}"; do
        if [[ "${PROFILES[$i]}" == "$current" ]]; then
            next=$(( (i + 1) % ${#PROFILES[@]} ))
            powerprofilesctl set "${PROFILES[$next]}"
            notify-send "Power profile" "${PROFILES[$next]}" 2>/dev/null || true
            return
        fi
    done
    powerprofilesctl set balanced
    notify-send "Power profile" "balanced" 2>/dev/null || true
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
