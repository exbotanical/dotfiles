# Makes each application in the mime list the default handler for its MIME type. Without a
# default, GIO and xdg-mime pick the first handler in mimeinfo.cache, which is alphabetical by
# desktop entry.

module::applies () {
  [[ $PROFILE == desktop ]]
}

module::install () {
  local mime_type app
  while read -r mime_type app; do
    set_default "$mime_type" "$(desktop_entry "$app")"
  done < <(bootstrap::packages mime)
}

module::outdated () {
  :
}

# Prints the desktop entry that the distro's package for application $1 installs.
desktop_entry () {
  case $DISTRO:$1 in
    arch:vscodium) printf 'codium.desktop' ;;
    ubuntu:vscodium) printf 'com.visualstudio.CodeOSS.desktop' ;;
    *) printf '%s.desktop' "$1" ;;
  esac
}

set_default () {
  local mime_type=$1 handler=$2

  if [[ $(xdg-mime query default "$mime_type") == "$handler" ]]; then
    log "[=] $mime_type: $handler"
    return 0
  fi

  xdg-mime default "$handler" "$mime_type"
  log "[+] $mime_type: $handler"
}
