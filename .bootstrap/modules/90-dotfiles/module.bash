# Runs make install, which stows the packages and runs their postinstall targets.

module::applies () {
  :
}

module::install () {
  # make install calls npm ci, so load the node that 40-node installed.
  set +u
  source "$HOME/.config/nvm/nvm.sh"
  set -u
  make -C "$REPO_DIR" install
}

module::outdated () {
  :
}
