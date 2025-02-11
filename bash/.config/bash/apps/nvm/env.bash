# Note: migrate modules via `nvm install node --reinstall-packages-from=<prev>`
if utils::macos?; then
  NVM_ConfigDir=$HOME/.nvm
else
  NVM_ConfigDir=$HOME/.config/nvm
fi

init::export NVM_DIR $NVM_ConfigDir
