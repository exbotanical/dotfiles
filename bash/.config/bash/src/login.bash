# Copy scripts to user-local executables dir
(
  init::debug 'Loading scripts'
  support::globbing on

  for file in $RootDir/scripts/*; do
    init::debug "Loading script $file"

    chmod u+x $file
    file_name=$(basename $file)
    rsync -u $file $ExecDir/${file_name%.*}
  done
)

init::feature_enabled? WMOnStartup && {
  init::debug 'WMOnStartup enabled'

  [ -z $DISPLAY ] && (( XDG_VTNR == 1 )) && exec startx
}

init::feature_enabled? EnableEmscriptenEnv && {
  init::debug 'EnableEmscriptenEnv enabled'
  # Emscripten
  init::source? "/usr/src/emsdk/emsdk_env.sh"
}
