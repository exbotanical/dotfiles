# Installs nvm into the directory apps/nvm/env.bash exports as NVM_DIR, then makes the current
# node LTS the default. When the default is an older version, the new LTS gets its global packages.
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
current=$(nvm version default)
lts=$(nvm version-remote --lts)

if [[ $lts != v* ]]; then
  [[ $current == v* ]] || die '[!] cannot read the node LTS version and no default node is installed'
  log "[=] node $current (the LTS version is unavailable offline)"
  exit 0
fi

if [[ $current == "$lts" ]]; then
  log "[=] node $lts (LTS)"
  exit 0
fi

if [[ $current == v* ]]; then
  nvm install "$lts" --reinstall-packages-from=default
else
  nvm install "$lts"
fi
nvm alias default "$lts"
