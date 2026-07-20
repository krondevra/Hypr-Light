#!/bin/sh
GPU_PATH="/sys/class/drm/card0/device/gpu_busy_percent"

if [ -r "$GPU_PATH" ]; then
  usage=$(cat "$GPU_PATH")
  printf '%s\n' "$usage"
else
  printf '0\n'
fi
