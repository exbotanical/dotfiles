### Initializations {{{
# LSCOLORS config
if [[ -e $HOME/.dir_colors/nord.dircolors ]]; then
  eval "$(dircolors "$HOME/.dir_colors/nord.dircolors")"
fi

# GCC color config
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Prompts
PS2="\[$(tput setaf 3)\]continue--> "
export PS2

# oh-my-posh PS1 prompt
eval "$(oh-my-posh init bash --config "$HOME/dotfiles/ohmyposh/.ohmyposh/themes/nord.omp.json")"
### End Initializations ### }}}
