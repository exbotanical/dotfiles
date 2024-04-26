# Copy scripts to user-local executables dir
(
  init::debug 'Loading scripts'
  support::globbing on

  for file in $Root/scripts/*; do
    init::debug "Loading script $file"

    chmod u+x $file
    file_name=$(basename $file)
    cp -u $file $ExecDir/${file_name%.*}
  done
)

init::feature_enabled WMONSTARTUP && {
  init::debug 'WMONSTARTUP enabled'

  [ -z $DISPLAY ] && [ $XDG_VTNR -eq 1 ] && exec startx
}

init::feature_enabled NIGHTMODE && (
  init::debug 'NIGHTMODE enabled - checking backlight'

  is_night=$(date +%H:%M)
  if [[ $is_night > '20:00' ]] || [[ $is_night < '06:00' ]]; then
    light -S 1
  fi
)

# Emscripten
# init::source? "/usr/src/emsdk/emsdk_env.sh"
