DIR_COLORS_FILE='ghost.dircolors'
DIR_COLORS_DIR=$HOME/.config/dircolors

EphemeralVars+=(DIR_COLORS_FILE DIR_COLORS_DIR)

[[ -e $DIR_COLORS_DIR/$DIR_COLORS_FILE ]] && {
  eval "$(dircolors $DIR_COLORS_DIR/$DIR_COLORS_FILE)"
}
