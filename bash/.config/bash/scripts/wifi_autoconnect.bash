#!/usr/bin/env bash
# Sets connection.autoconnect on every saved Wi-Fi profile from two machine-local files of
# glob patterns, one per line, with # comments:
#   ~/.config/wifi/autoconnect  profiles that autoconnect
#   ~/.config/wifi/unmanaged    profiles left unchanged, such as ones an administrator installs
# Every other Wi-Fi profile is set to not autoconnect. Changes run through sudo, because
# NetworkManager requires root to modify a system-wide profile.

AUTOCONNECT=()
UNMANAGED=()

die () {
  printf '%s\n' "$@" >&2
  exit 1
}

# Prints the lines of a pattern file without comments and blank lines, and nothing for a
# missing file.
patterns () {
  [[ -f $1 ]] || return 0

  local line
  while IFS= read -r line || [[ -n $line ]]; do
    [[ -z $line || $line == \#* ]] && continue
    printf '%s\n' "$line"
  done < "$1"
}

matches_any () {
  local name=$1 pattern
  shift

  for pattern in "$@"; do
    # shellcheck disable=SC2053 # patterns are globs
    [[ $name == $pattern ]] && return 0
  done
  return 1
}

# Prints yes or no for a profile, and nothing for an unmanaged one.
autoconnect_value () {
  matches_any "$1" "${UNMANAGED[@]}" && return
  if matches_any "$1" "${AUTOCONNECT[@]}"; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
}

# nmcli's terse output escapes each colon in a name as \:.
wifi_profiles () {
  local line name
  nmcli -t -f TYPE,NAME connection show | while IFS= read -r line; do
    [[ $line == 802-11-wireless:* ]] || continue
    name=${line#802-11-wireless:}
    printf '%s\n' "${name//\\:/:}"
  done
}

main () {
  local config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/wifi
  mapfile -t AUTOCONNECT < <(patterns "$config_dir/autoconnect")
  mapfile -t UNMANAGED < <(patterns "$config_dir/unmanaged")
  ((${#AUTOCONNECT[@]} > 0)) || die "no patterns in $config_dir/autoconnect"

  local name wanted current
  while IFS= read -r name; do
    wanted=$(autoconnect_value "$name")
    [[ -n $wanted ]] || continue
    current=$(nmcli -g connection.autoconnect connection show id "$name") \
      || die "reading $name failed"
    [[ $current == "$wanted" ]] && continue
    sudo nmcli connection modify id "$name" connection.autoconnect "$wanted" \
      || die "setting autoconnect on $name failed"
    printf '%s: %s -> %s\n' "$name" "$current" "$wanted"
  done < <(wifi_profiles)
}

# stop here if being sourced
return 2> /dev/null

set -euo pipefail

main "$@"
