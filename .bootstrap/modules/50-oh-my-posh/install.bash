if has oh-my-posh; then
  log "[=] oh-my-posh $(oh-my-posh version)"
  exit 0
fi
mkdir -p "$HOME/.local/bin"
curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
