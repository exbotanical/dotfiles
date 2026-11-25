#!/usr/bin/env bash

# Brightness control script with dunst notifications
# Usage: brightness [up|down] [step]

set -euo pipefail

BRIGHTNESS_STEP="${2:-5}"

get_brightness () {
  brightnessctl -m | cut -d, -f4 | tr -d %
}

notify_brightness () {
  local brightness
  brightness=$(get_brightness)
  dunstify -a "brightness" -u low -r 9991 -h int:value:"$brightness" -i "display-brightness-symbolic" "Brightness: ${brightness}%"
}

case "${1:-}" in
  up)
    brightnessctl -q set "${BRIGHTNESS_STEP}%+"
    notify_brightness
    ;;
  down)
    brightnessctl -q set "${BRIGHTNESS_STEP}%-"
    notify_brightness
    ;;
  *)
    echo "Usage: $0 [up|down] [step]"
    echo "  up    - Increase brightness by step% (default: 5%)"
    echo "  down  - Decrease brightness by step% (default: 5%)"
    exit 1
    ;;
esac
