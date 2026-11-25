# Installs networkmanager-dmenu and rofi-bluetooth, the Wi-Fi and Bluetooth menus that the eww bar
# opens, because Ubuntu does not package them. The Arch AUR list installs them there. Each URL pins
# the commit whose script was reviewed.
readonly BIN_DIR=$HOME/.local/bin
readonly NETWORKMANAGER_DMENU_URL=https://raw.githubusercontent.com/firecat53/networkmanager-dmenu/acedf1a6faf2df904208e402d4293f13d1144489/networkmanager_dmenu
readonly ROFI_BLUETOOTH_URL=https://raw.githubusercontent.com/nickclyde/rofi-bluetooth/0cca4d4aa1c82c9373ce5da781d73683a29484c6/rofi-bluetooth

module::applies () {
  [[ $DISTRO == ubuntu && $PROFILE == desktop ]]
}

module::install () {
  work=
  trap 'rm -f "${work:-}"' EXIT

  install_script networkmanager_dmenu "$NETWORKMANAGER_DMENU_URL"
  install_script rofi-bluetooth "$ROFI_BLUETOOTH_URL"
}

# Reports each pinned commit that is no longer its repository's HEAD.
module::outdated () {
  local url repo commit
  for url in "$NETWORKMANAGER_DMENU_URL" "$ROFI_BLUETOOTH_URL"; do
    [[ $url =~ ^https://raw\.githubusercontent\.com/([^/]+/[^/]+)/([0-9a-f]{40})/ ]] || continue
    repo=${BASH_REMATCH[1]}
    commit=${BASH_REMATCH[2]}
    bootstrap::report_outdated "$repo" "$commit" "$(bootstrap::head_commit "https://github.com/$repo")"
  done
}

# Downloads the script at $2 to $BIN_DIR/$1, unless $1 is on the PATH.
install_script () {
  local name=$1 url=$2

  if has "$name"; then
    log "[=] $name"
    return
  fi

  # Downloads beside the destination so that the final mv is a rename, and an interrupted run
  # leaves no partial script for the next run to skip.
  mkdir -p "$BIN_DIR"
  work=$(mktemp "$BIN_DIR/.$name.XXXXXX")
  curl -fsSLo "$work" "$url"
  chmod 0755 "$work"
  mv "$work" "$BIN_DIR/$name"
  log "[+] $name"
}
