# Installs nvm into the directory apps/nvm/env.bash exports as NVM_DIR, then the LTS node.
# PROFILE=/dev/null stops the nvm installer from appending to the stowed ~/.bashrc.
readonly NVM_INSTALLER_VERSION=v0.40.8
export NVM_DIR=$HOME/.config/nvm

if [[ ! -s $NVM_DIR/nvm.sh ]]; then
  mkdir -p "$NVM_DIR"
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_INSTALLER_VERSION/install.sh" \
    | PROFILE=/dev/null bash
fi

# nvm.sh reads unset variables and fails under nounset.
set +u
source "$NVM_DIR/nvm.sh"
if [[ $(nvm version default) == v* ]]; then
  log "[=] node $(nvm version default)"
else
  nvm install --lts
fi
