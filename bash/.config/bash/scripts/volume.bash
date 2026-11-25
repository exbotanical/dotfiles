#!/usr/bin/env bash

# Volume control script with dunst notifications
# Usage: volume [up|down|mute] [step]

set -euo pipefail

VOLUME_STEP="${2:-5}"

# Prints the default sink's volume in percent. pactl prints a percentage per channel, and awk
# keeps the first and reads to the end, because an early exit can end pactl with SIGPIPE.
get_volume () {
  pactl get-sink-volume @DEFAULT_SINK@ | awk '!found && match($0, /[0-9]+%/) { print substr($0, RSTART, RLENGTH - 1); found = 1 }'
}

is_muted () {
  [[ $(pactl get-sink-mute @DEFAULT_SINK@) == 'Mute: yes' ]]
}

notify_volume () {
  local volume
  volume=$(get_volume)

  if is_muted; then
    notify-send -a "volume" -u low -r 9992 -h int:value:"$volume" -i "audio-volume-muted-symbolic" "Volume (Muted)" "${volume}%"
  else
    notify-send -a "volume" -u low -r 9992 -h int:value:"$volume" -i "audio-volume-high-symbolic" "Volume" "${volume}%"
  fi
}

case "${1:-}" in
  up)
    pactl set-sink-volume @DEFAULT_SINK@ "+${VOLUME_STEP}%"
    notify_volume
    ;;
  down)
    pactl set-sink-volume @DEFAULT_SINK@ "-${VOLUME_STEP}%"
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
