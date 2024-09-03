DIR_COLORS_FILE='dracula.dircolors'
DIR_COLORS_DIR=$HOME/.dir_colors

EphemeralVars+=( DIR_COLORS_FILE DIR_COLORS_DIR )

[[ -e $DIR_COLORS_DIR/$DIR_COLORS_FILE ]] && {
  eval "$(dircolors $DIR_COLORS_DIR/$DIR_COLORS_FILE)"
}

# In AL2 linux, this is a file and not a dir
[[ -e $HOME/$DIR_COLORS_FILE ]] && {
  eval "$(dircolors $HOME/$DIR_COLORS_FILE)"
}
