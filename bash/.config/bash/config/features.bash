get_flag () {
  local bin="$1"
  echo $(( $(type $bin &>/dev/null; echo $?) == 0 ? 1 : 0 ))
}

# Print debug statements
DebugMode=$DEBUG
# Lower screen brightness after hours
NightMode=1
# Launch window manager on startup
WMOnStartup=1
# Remap the capslock key to super
RemapCapslockToSuper=1
# Use lsd in place of ls
UseLsd=$(get_flag lsd)
# Use ripgrep (rg) in place of grep
UseRipgrep=$(get_flag rg)
# Source Emscripten env on login
EnableEmscriptenEnv=0

EphemeralVars+=(
  DebugMode
  NightMode
  WMOnStartup
  RemapCapslockToSuper
  UseLsd
  UseRipgrep
  EnableEmscriptenEnv
  get_flag
)
