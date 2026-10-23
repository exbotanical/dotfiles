# Installs rustup into ~/.cargo, where apps/rust/detect.bash looks for it. --no-modify-path stops
# rustup from editing the stowed bash files.
if [[ -x $HOME/.cargo/bin/rustup ]]; then
  log "[=] $(rustup --version 2> /dev/null)"
  exit 0
fi
curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
