# Installs nvm into the directory apps/nvm/env.bash exports as NVM_DIR, then makes the current
# node LTS the default. When the default is an older version, the new LTS gets its global packages.
# PROFILE=/dev/null stops the nvm installer from appending to the stowed ~/.bashrc.
readonly NVM_INSTALLER_VERSION=v0.40.8
readonly NVM_REPO=https://github.com/nvm-sh/nvm

module::applies () {
  :
}

module::install () {
  export NVM_DIR=$HOME/.config/nvm

  if [[ ! -s $NVM_DIR/nvm.sh ]]; then
    mkdir -p "$NVM_DIR"
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_INSTALLER_VERSION/install.sh" \
      | PROFILE=/dev/null bash
  fi

  # nvm.sh reads unset variables and fails under nounset.
  set +u
  source "$NVM_DIR/nvm.sh"
  local current lts
  # Each prints N/A and exits 3 when there is no default node or the LTS is unreachable.
  current=$(nvm version default || true)
  lts=$(nvm version-remote --lts || true)

  if [[ $lts != v* ]]; then
    [[ $current == v* ]] || die '[!] cannot read the node LTS version and no default node is installed'
    log "[=] node $current (the LTS version is unavailable offline)"
    return 0
  fi

  if [[ $current == "$lts" ]]; then
    log "[=] node $lts (LTS)"
    return 0
  fi

  if [[ $current == v* ]]; then
    nvm install "$lts" --reinstall-packages-from=default
  else
    nvm install "$lts"
  fi
  nvm alias default "$lts"
}

# Reports a newer nvm installer than the pinned one. Node itself follows the LTS on install.
module::outdated () {
  bootstrap::report_outdated 'nvm installer' "$NVM_INSTALLER_VERSION" "$(bootstrap::latest_tag "$NVM_REPO")"
}
