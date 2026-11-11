#!/usr/bin/env bash

# Opens an eww bar on every connected monitor and closes each bar whose monitor
# is disconnected. Each bar's id is bar-<monitor> (like the monitor names that
# xrandr --listmonitors prints), which eww matches on X11.
# Each bar opens with GDK_DPI_SCALE from EWW_GDK_DPI_SCALE, which ~/.xprofile sets.
# Usage: bar

set -euo pipefail

readonly LOCK_FILE=${XDG_RUNTIME_DIR:-/tmp}/eww-bar.lock

# Prints the name of each connected monitor, one per line. The name is the
# second field of each xrandr --listmonitors line, after its + (active) and
# * (primary) flags.
monitors () {
  xrandr --listmonitors | awk 'NR > 1 { sub(/^[+*]+/, "", $2); print $2 }'
}

# Prints the id of each open bar, one per line.
open_bars () {
  eww active-windows | awk -F ': ' '$2 == "bar" { print $1 }'
}

main () {
  local -a names windows=() args=() flags=()
  local name id

  # i3 runs this at startup while autorandr's postswitch hook may run it too;
  # without the lock, both runs could see no daemon and start one each.
  exec 9> "$LOCK_FILE"
  flock 9

  mapfile -t names < <(monitors)

  if eww ping > /dev/null 2>&1; then
    while read -r id; do
      if [[ " ${names[*]} " != *" ${id#bar-} "* ]]; then
        eww close "$id"
      fi
    done < <(open_bars)

    # A running daemon that takes over 100 ms to reply, e.g. while it handles a
    # monitor change, makes eww start a second daemon; --no-daemonize stops it.
    flags=(--no-daemonize)
  fi

  for name in "${names[@]}"; do
    windows+=("bar:bar-$name")
    args+=(--arg "bar-$name:screen=$name")
  done

  # 9>&- keeps a daemon that open-many starts from inheriting (and thus holding) the lock.
  GDK_DPI_SCALE=${EWW_GDK_DPI_SCALE:-1} eww "${flags[@]}" open-many "${windows[@]}" "${args[@]}" 9>&-
}

main
