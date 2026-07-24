#!/bin/sh
GPU_PATH="/sys/class/drm/card0/device/gpu_busy_percent"

if [ -r "$GPU_PATH" ]; then
  usage=$(cat "$GPU_PATH")
else
  usage=0
fi

printf '{"text": "GPU %s%%", "tooltip": "GPU usage"}\n' "$usage"
