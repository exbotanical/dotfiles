DEFAULT_HEADPHONES_MACADDR='98:47:44:C0:63:F8'

# blue_conn connects a bluetooth device by its MAC address
blue_conn () {
  local macaddr="${1:-$DEFAULT_HEADPHONES_MACADDR}"

  # must have edited config rules
  bluetoothctl connect $macaddr
}

blue_reset () {
  local macaddr="${1:-$DEFAULT_HEADPHONES_MACADDR}"

  bluetoothctl disconnect $macaddr && blue_conn $macaddr
}
