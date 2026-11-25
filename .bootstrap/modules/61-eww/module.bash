# Builds eww for X11, as elkowar.github.io/eww documents, because Ubuntu does not package it.
# The Arch AUR list installs it there.

module::applies () {
  [[ $DISTRO == ubuntu && $PROFILE == desktop ]]
}

module::install () {
  if has eww; then
    log "[=] $(eww --version)"
    return 0
  fi

  build_dir=$(mktemp -d)
  trap 'rm -rf "$build_dir"' EXIT
  git clone --depth 1 https://github.com/elkowar/eww "$build_dir"
  (cd "$build_dir" && cargo build --release --no-default-features --features x11)
  sudo install -m 0755 "$build_dir/target/release/eww" /usr/local/bin/eww
}

# Install builds the default branch once and pins no commit, so there is no pin to compare.
module::outdated () {
  :
}
