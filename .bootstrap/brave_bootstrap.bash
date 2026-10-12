#!/usr/bin/env bash
# Ubuntu installs Brave as brave-browser, while Arch (AUR brave-bin) installs it as brave.
# The i3 and dunst configs launch brave, so link it on Ubuntu.
set -euo pipefail

readonly TARGET=/usr/bin/brave-browser
readonly LINK=/usr/bin/brave

die () {
  printf '%s\n' "$@" >&2
  exit 1
}

main () {
  local id
  id=$(. /etc/os-release && printf '%s' "$ID")
  if [[ "$id" != ubuntu ]]; then
    printf '[-] Skipping brave symlink on %s\n' "$id"
    return
  fi

  [[ -x "$TARGET" ]] || die "$TARGET not found; install Brave first"
  if [[ -e "$LINK" && ! -L "$LINK" ]]; then
    die "$LINK exists and is not a symlink"
  fi

  sudo ln -sfn "$TARGET" "$LINK"
  printf '[+] Sym-linked %s to %s\n' "$LINK" "$TARGET"
}

main
