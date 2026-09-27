#!/usr/bin/env bash

# Night mode control script with dunst notifications
# Usage: night [apply|toggle|on|off|warm|auto|status]

# Settings live here rather than in a redshift.conf because Ubuntu's AppArmor
# profile (/etc/apparmor.d/usr.bin.redshift) permits reading only the literal
# path @{HOME}/.config/redshift.conf, and mediates resolved paths -- so a
# stow symlink into ~/dotfiles is always denied. Flags open no file at all.

set -euo pipefail

# Seattle
readonly LOCATION='47.61:-122.33'

readonly DAY_TEMP=6500
readonly NIGHT_TEMP=1900

# Gamma brightness, not backlight -- black stays black and contrast drops, so
# keep it mild and use `brightness` for the actual panel.
readonly DAY_BRIGHTNESS=1.0
readonly NIGHT_BRIGHTNESS=0.85

readonly METHOD=randr

readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/night"
readonly OVERRIDE_FILE="$STATE_DIR/override"

# Asks redshift what the schedule wants right now, printing the period class,
# color temperature and brightness. Print mode reports interpolated values
# mid-twilight, so stepping on a timer tracks the dusk ramp. The period is
# deliberately coarse -- the transition percentage moves every tick and would
# otherwise expire an override immediately.
read_schedule() {
  redshift \
    -l "$LOCATION" \
    -t "$DAY_TEMP:$NIGHT_TEMP" \
    -b "$DAY_BRIGHTNESS:$NIGHT_BRIGHTNESS" \
    -m "$METHOD" \
    -p 2> /dev/null \
    | awk '
      /^Period:/            { period = $2 }
      /^Color temperature:/ { temp = $3; sub(/K$/, "", temp) }
      /^Brightness:/        { brightness = $2 }
      END                   { print period, temp, brightness }
    '
}

current_period() {
  read_schedule | cut -d' ' -f1
}

# -P resets the ramps to pure before applying. Without it redshift composes onto
# whatever is already on screen, and a fresh process every tick would compound
# its own warmth without bound.
apply_values() {
  redshift -P -O "$1" -b "$2" -m "$METHOD" &> /dev/null
}

clear_gamma() {
  redshift -m "$METHOD" -x &> /dev/null
}

read_override() {
  [[ -f $OVERRIDE_FILE ]] && cat "$OVERRIDE_FILE" || true
}

write_override() {
  mkdir -p "$STATE_DIR"
  printf '%s %s\n' "$1" "$2" >| "$OVERRIDE_FILE"
}

clear_override() {
  rm -f "$OVERRIDE_FILE"
}

get_mode() {
  local override
  override=$(read_override)

  if [[ -n $override ]]; then
    printf '%s\n' "${override#* }"
  else
    printf 'schedule\n'
  fi
}

notify() {
  local state="$1"
  local label="${2:-$state}"
  local icon=weather-clear

  [[ $state == on ]] && icon=weather-clear-night

  dunstify -a "night" -u low -r 9992 -i "$icon" "Night mode: ${label}"
}

apply_mode() {
  local mode="$1"
  local sched_temp="$2"
  local sched_brightness="$3"

  case $mode in
    off) clear_gamma ;;
    warm:*) apply_values "${mode#warm:}" "$NIGHT_BRIGHTNESS" ;;
    *) apply_values "$sched_temp" "$sched_brightness" ;;
  esac
}

# Timer entry point, silent by design. An override wins only while the period it
# was recorded in is still current, so daytime toggling is discarded at dusk and
# the schedule resumes at its own values. Re-asserting every tick is also what
# heals gamma clobbered by a monitor coming online.
apply() {
  local period temp brightness
  read -r period temp brightness < <(read_schedule)

  if [[ -z $period ]]; then
    printf 'night: could not read the schedule from redshift\n' >&2
    exit 1
  fi

  local override override_period mode
  override=$(read_override)

  if [[ -n $override ]]; then
    read -r override_period mode <<< "$override"

    if [[ $override_period == "$period" ]]; then
      apply_mode "$mode" "$temp" "$brightness"
      return 0
    fi

    clear_override
  fi

  apply_values "$temp" "$brightness"
}

warm() {
  local temp="${1:-$NIGHT_TEMP}"

  write_override "$(current_period)" "warm:$temp"
  apply_values "$temp" "$NIGHT_BRIGHTNESS"
  notify on "${temp}K"
}

on() {
  warm "$NIGHT_TEMP"
}

off() {
  write_override "$(current_period)" off
  clear_gamma
  notify off
}

auto() {
  clear_override
  apply
  notify on auto
}

toggle() {
  local mode
  mode=$(get_mode)

  case $mode in
    off) on ;;
    warm:*) off ;;
    *)
      if [[ $(current_period) == Daytime ]]; then
        on
      else
        off
      fi
      ;;
  esac
}

status() {
  local period temp brightness
  read -r period temp brightness < <(read_schedule)

  local override
  override=$(read_override)

  printf 'period:    %s\n' "$period"
  printf 'scheduled: %sK @ %s brightness\n' "$temp" "$brightness"
  printf 'override:  %s\n' "${override:-none}"
  printf 'applied:   %s\n' \
    "$(xrandr --verbose | awk '/Gamma:/ { gsub(/[ \t]+/, " "); print $2; exit }')"
}

case "${1:-}" in
  apply) apply ;;
  toggle) toggle ;;
  on) on ;;
  off) off ;;
  warm) warm "${2:-}" ;;
  auto) auto ;;
  status) status ;;
  *)
    echo "Usage: $0 [apply|toggle|on|off|warm|auto|status]"
    echo "  apply     - Apply the correct color for right now (timer entry point)"
    echo "  toggle    - Flip between warm and neutral at any hour"
    echo "  on        - Force warm now (${NIGHT_TEMP}K)"
    echo "  off       - Force neutral now"
    echo "  warm [K]  - Force warm now at a given temperature"
    echo "  auto      - Drop any override and follow the schedule"
    echo "  status    - Print period, schedule, override and applied gamma"
    exit 1
    ;;
esac
