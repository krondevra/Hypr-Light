#!/bin/bash
# Battery status for waybar. Unlike Waybar's built-in battery module (which
# vanishes entirely when no battery device exists), this always shows
# something: real icon+percentage when a battery is present, or an explicit
# "no battery" indicator when it isn't (e.g. this repo's own test VM).
set -euo pipefail

BAT=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | head -1)

if [ -z "$BAT" ]; then
    echo '{"text": "󰂑 no battery", "tooltip": "No battery detected"}'
    exit 0
fi

capacity=$(cat "$BAT/capacity" 2>/dev/null || echo 0)
status=$(cat "$BAT/status" 2>/dev/null || echo "Unknown")

if [ "$status" = "Charging" ]; then
    icon="󰂄"
else
    if   [ "$capacity" -ge 90 ]; then icon=""
    elif [ "$capacity" -ge 65 ]; then icon=""
    elif [ "$capacity" -ge 35 ]; then icon=""
    elif [ "$capacity" -ge 15 ]; then icon=""
    else                              icon=""
    fi
fi

class="normal"
[ "$capacity" -le 30 ] && class="warning"
[ "$capacity" -le 15 ] && class="critical"

printf '{"text": "%s %s%%", "tooltip": "Battery: %s%% (%s) — click to cycle power profile", "class": "%s"}\n' \
    "$icon" "$capacity" "$capacity" "$status" "$class"
