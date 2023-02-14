# LSCOLORS config
LS_COLORS_DIR="$HOME/.dir_colors/nord.dircolors"
EphemeralVars+=( LS_COLORS_DIR )
[[ -e $LS_COLORS_DIR ]] && {
  eval "$(dircolors $LS_COLORS_DIR)"
}
