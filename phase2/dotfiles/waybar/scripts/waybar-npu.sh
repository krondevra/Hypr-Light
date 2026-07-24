#!/bin/bash
# NPU status for AMD XDNA (used by fastflowlm), shown as a Waybar custom module.
#
# NOTE: live NPU load percentage is not reliably exposed by the amdxdna driver yet
# on most kernels (power/telemetry queries commonly return -EOPNOTSUPP upstream),
# so this reports device presence rather than a fabricated usage number.
set -euo pipefail

if ! command -v xrt-smi &>/dev/null; then
    echo '{"text": "󰢮 n/a", "tooltip": "xrt-smi not found — is xrt-plugin-amdxdna installed?"}'
    exit 0
fi

if xrt-smi examine &>/dev/null; then
    echo '{"text": "󰢮", "tooltip": "NPU device detected (xrt-smi examine OK)"}'
else
    echo '{"text": "󰢮 off", "tooltip": "NPU device not detected"}'
fi
