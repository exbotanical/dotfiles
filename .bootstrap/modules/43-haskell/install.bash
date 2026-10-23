# Installs ghcup into ~/.ghcup, where apps/ghc/detect.bash looks for it. In non-interactive mode
# without BOOTSTRAP_HASKELL_ADJUST_BASHRC, the installer leaves ~/.bashrc unchanged.
if [[ -x $HOME/.ghcup/bin/ghcup ]]; then
  log "[=] $(ghcup --version)"
  exit 0
fi
curl --proto '=https' --tlsv1.2 -fsSL https://get-ghcup.haskell.org \
  | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh
