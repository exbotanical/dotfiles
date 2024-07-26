# Note: migrate modules via `nvm install node --reinstall-packages-from=<prev>`
# shellcheck disable=SC2157,SC2203
if [[ support::macos? ]]; then
  NVM_CONFIG_DIR=$HOME/.nvm
else
  NVM_CONFIG_DIR=$HOME/.config/nvm
fi

init::export NVM_DIR $NVM_CONFIG_DIR
