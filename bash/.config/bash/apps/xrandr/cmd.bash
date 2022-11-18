# mon sets the screen layout
mon () {
  local mode="$1"

  if [[ -z "$mode" ]]; then
    echo "[-] No argument supplied."
    exit 1
  fi

  local main_monitor='eDP-1'
  case $mode in
    1)
      xrandr --output "$main_monitor" --primary --mode 1920x1200 \
      --pos 0x0 --rotate normal \
      --output DP-1 --off --output HDMI-1 --off \
      --output DP-2 --off --output DP-3 --off \
      --output DP-4 --off --output DP-3-1 --off \
      --output DP-3-2 --off --output DP-3-3 --off \
      --output DP-1-1 --off --output DP-1-2 --off \
      --output DP-1-3 --off
      ;;
    2)
      xrandr --output "$main_monitor" --primary --mode 1920x1200 \
      --pos 1920x0 --rotate normal \
      --output DP-1 --off --output HDMI-1 --off \
      --output DP-2 --off --output DP-3 --off \
      --output DP-4 --off \
      --output DP-1-1 --mode 1920x1080 --pos 0x0 --rotate normal \
      --output DP-1-2 --mode 1920x1080 --pos 0x1080 --rotate normal \
      --output DP-1-3 --off
      ;;
    3)
      xrandr --output "$main_monitor" --primary --mode 1920x1200 \
      --pos 1920x0 --rotate normal \
      --output DP-1 --off --output HDMI-1 --off \
      --output DP-2 --off --output DP-3 --off \
      --output DP-4 --off \
      --output DP-1-1 --mode 1920x1080 --pos 0x0 --rotate normal \
      --output DP-1-2 --mode 1920x1080 --pos 0x1080 --rotate normal \
      --output DP-1-3 --off
      ;;
    4)
      xrandr --output "$main_monitor" --primary --mode 1920x1200 \
      --pos 3000x720 --rotate normal \
      --output DP-1 --off --output HDMI-1 --off \
      --output DP-2 --off --output DP-3 --off \
      --output DP-4 --off \
      --output DP-1-1 --mode 1920x1080 --pos 1080x0 --rotate normal \
      --output DP-1-2 --mode 1920x1080 --pos 1080x1080 --rotate normal \
      --output DP-1-3 --mode 1920x1080 --pos 0x0 --rotate left
      ;;
    *)
      echo "[-] '$mode' is not a valid option"
      exit 1
      ;;
  esac
}

# darken lowers the screen brightness beyond the percentage
darken () {
  local percentage="${1:-.7}"
  local default_output="eDP-1"

  xrandr --output $default_output --brightness "$percentage"
}