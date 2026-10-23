# Builds eww for X11, as elkowar.github.io/eww documents, because Ubuntu does not package it.
# The Arch AUR list installs it there.
if has eww; then
  log "[=] $(eww --version)"
  exit 0
fi

build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT
git clone --depth 1 https://github.com/elkowar/eww "$build_dir"
(cd "$build_dir" && cargo build --release --no-default-features --features x11)
sudo install -m 0755 "$build_dir/target/release/eww" /usr/local/bin/eww
