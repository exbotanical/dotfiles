# Copy scripts to user-local executables dir; lib/apps.bash copies each loaded app's scripts
init::debug 'Loading scripts'
init::install_scripts $RootDir/scripts

init::feature_enabled? WMOnStartup && {
  init::debug 'WMOnStartup enabled'

  [ -z $DISPLAY ] && ((XDG_VTNR == 1)) && exec startx
}

init::feature_enabled? EnableEmscriptenEnv && {
  init::debug 'EnableEmscriptenEnv enabled'
  # Emscripten
  init::source? "/usr/src/emsdk/emsdk_env.sh"
}
