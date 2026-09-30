#!/usr/bin/env bash

# Volume control script with dunst notifications
# Usage: volume [up|down|mute] [step]

set -euo pipefail

VOLUME_STEP="${2:-5}"

get_volume () {
  pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}' | sed 's/[^0-9]*//g'
}

is_muted () {
  pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes'
}

notify_volume () {
  local volume
  volume=$(get_volume)

  if is_muted; then
    dunstify -a "volume" -u low -r 9992 -h int:value:"$volume" -i "audio-volume-muted-symbolic" "Volume (Muted)" "${volume}%"
  else
    dunstify -a "volume" -u low -r 9992 -h int:value:"$volume" -i "audio-volume-high-symbolic" "Volume" "${volume}%"
  fi
}

case "${1:-}" in
  up)
    pactl set-sink-volume @DEFAULT_SINK@ +${VOLUME_STEP}%
    notify_volume
    ;;
  down)
    pactl set-sink-volume @DEFAULT_SINK@ -${VOLUME_STEP}%
    notify_volume
    ;;
  mute)
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    notify_volume
    ;;
  *)
    echo "Usage: $0 [up|down|mute] [step]"
    echo "  up    - Increase volume by step% (default: 5%)"
    echo "  down  - Decrease volume by step% (default: 5%)"
    echo "  mute  - Toggle mute status"
    exit 1
    ;;
esac
