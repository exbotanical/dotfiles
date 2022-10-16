#!/bin/sh

USER_RESOURCES=$HOME/.Xresources
USER_MOD_MAP=$HOME/.Xmodmap
SYS_RESOURCES=/etc/X11/xinit/.Xresources
SYS_MOD_MAP=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps
merge_resources () {
  if [ -f $SYS_RESOURCES ]; then
    xrdb -merge $SYS_RESOURCES
  fi

  if [ -f $SYS_MOD_MAP ]; then
    xmodmap $SYS_MOD_MAP
  fi

  if [ -f "$USER_RESOURCES" ]; then
    xrdb -merge "$USER_RESOURCES"
  fi

  if [ -f "$USER_MOD_MAP" ]; then
    xmodmap "$USER_MOD_MAP"
  fi
}

# Initialize programs
init () {
  if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
      [ -x "$f" ] && . "$f"
    done

    unset f
  fi

  exec i3
}

merge_resources
init
