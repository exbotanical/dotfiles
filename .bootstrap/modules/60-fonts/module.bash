# Installs FiraCode Nerd Font, which the alacritty and VSCodium configs use. No distro packages it.
readonly FONT_DIR=$HOME/.local/share/fonts/firacode-nerd-font

module::applies () {
  [[ $PROFILE == desktop ]]
}

module::install () {
  if [[ -d $FONT_DIR ]]; then
    log '[=] FiraCode Nerd Font'
    return 0
  fi

  archive=$(mktemp)
  trap 'rm -f "$archive"' EXIT
  curl -fsSLo "$archive" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz
  mkdir -p "$FONT_DIR"
  tar -C "$FONT_DIR" -xJf "$archive"
  fc-cache -f "$FONT_DIR"
}

# Install downloads the latest release once and records no version, so there is no pin to compare.
module::outdated () {
  :
}
