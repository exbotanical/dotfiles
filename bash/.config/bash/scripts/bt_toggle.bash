#!/usr/bin/env bash
DEFAULT_HEADPHONES_MAC='34:09:C9:B2:A8:F6'

bt_toggle() {
  local mac="${1:-$DEFAULT_HEADPHONES_MAC}"

  if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
    bluetoothctl disconnect "$mac"
  else
    bluetoothctl connect "$mac"
  fi
}

bt_toggle
