# blue_conn connects a bluetooth device by its MAC address
blue_conn () {
  local default='28:F0:33:D0:61:14'

  # must have edited config rules
  bluetoothctl connect "${1:-$default}"
}
