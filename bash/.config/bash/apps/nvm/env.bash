# Note: migrate modules via `nvm install node --reinstall-packages-from=<prev>`
init::export NVM_DIR $HOME/.config/nvm

# Load NVM
[ -s "$NVM_DIR/nvm.sh" ] && {
  source $NVM_DIR/nvm.sh
}

# Load NVM completions
[ -s "$NVM_DIR/bash_completion" ] && {
  source $NVM_DIR/bash_completion
}
