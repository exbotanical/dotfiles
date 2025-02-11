init::feature_enabled? NightMode && (
  init::debug 'NightMode enabled - checking backlight'

  is_night=$(date +%H:%M)
  if [[ $is_night > '20:00' ]] || [[ $is_night < '06:00' ]]; then
    if ! utils::vscodium?; then
      light -S 1
    fi
  fi
)
