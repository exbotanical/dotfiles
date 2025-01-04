# Print debug statements
DebugMode=0
# Lower screen brightness after hours
NightMode=1
# Launch window manager on startup
WMOnStartup=1
# Remap the capslock key to super
RemapCapslockToSuper=1
# Use lsd in place of ls
UseLsd=1
# Use ripgrep (rg) in place of grep
UseRipgrep=1
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
)
