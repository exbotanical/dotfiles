#!/usr/bin/env bash

# Our custom ~/.xprofile uses bash syntax.
# Given xinit may run this file with sh (which will ignore the preceding shebang), we rerun it in bash.
# The following line itself is POSIX-compliant sh syntax.
[ -n "${BASH_VERSION:-}" ] || exec bash "$0" "$@"

USER_MOD_MAP=$HOME/.Xmodmap
SYS_RESOURCES=/etc/X11/xinit/.Xresources
SYS_MOD_MAP=/etc/X11/xinit/.Xmodmap

# Merge in defaults and keymaps
merge_resources () {
  if [ -f $SYS_RESOURCES ]; then
    xrdb -merge $SYS_RESOURCES
  fi

  if [ -f $SYS_MOD_MAP ]; then
    xmodmap $SYS_MOD_MAP
  fi

  if [ -f "$USER_MOD_MAP" ]; then
    xmodmap "$USER_MOD_MAP"
  fi
}

# Initialize X programs
init () {
  if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
      [ -x "$f" ] && . "$f"
    done

    unset f
  fi

  # User resources, themes, and session environment, shared with display manager logins.
  if [ -f "$HOME/.xprofile" ]; then
    . "$HOME/.xprofile"
  fi

  exec i3
}

merge_resources
init
