# Installs oh-my-posh into ~/.local/bin with its installer.

module::applies () {
  :
}

module::install () {
  if has oh-my-posh; then
    log "[=] oh-my-posh $(oh-my-posh version)"
    return 0
  fi
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
}

# The installer installs the latest release and the module pins none, so there is no pin to
# compare; oh-my-posh upgrade upgrades it.
module::outdated () {
  :
}
