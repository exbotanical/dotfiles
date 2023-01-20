# darken lowers the screen brightness beyond the percentage
darken () {
  local percentage="${1:-.7}"
  local default_output="eDP-1"

  xrandr --output $default_output --brightness "$percentage"
}


# mon_3 switches to a tri-monitor layout
mon_3 () {
  xrandr --output eDP-1 --primary --mode 2256x1504 --pos 0x416 --rotate normal \
  --output DP-1 --mode 3840x2160 --pos 3336x0 --rotate normal                  \
  --output DP-2 --mode 1920x1080 --pos 2256x0 --rotate left                    \
  --output DP-3 --off --output DP-4 --off
}

# mon_default resets the display configurations to the defaults
mon_default () {
  xrandr -s 0
}
