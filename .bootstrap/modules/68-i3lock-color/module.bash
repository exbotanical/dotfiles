# Builds i3lock-color, which i3/.config/i3/lock runs, because Ubuntu packages only plain i3lock. The
# Arch AUR list installs it there, as i3lock. The upstream installer also installs the binary as
# i3lock, over apt's, so this installs only the binary, as i3lock-color, and keeps apt's i3lock
# for the /etc/pam.d/i3lock service that i3lock-color authenticates through.
readonly VERSION=2.13.c.5
readonly REPO=https://github.com/Raymo111/i3lock-color

module::applies () {
  [[ $DISTRO == ubuntu && $PROFILE == desktop ]]
}

module::install () {
  if has i3lock-color; then
    log "[=] $(i3lock-color --version 2>&1)"
    return 0
  fi

  build_dir=$(mktemp -d)
  trap 'rm -rf "$build_dir"' EXIT
  git clone --depth 1 --branch "$VERSION" "$REPO" "$build_dir"
  (cd "$build_dir" && ./build.sh)
  sudo install -m 0755 "$build_dir/build/i3lock" /usr/local/bin/i3lock-color
}

module::outdated () {
  bootstrap::report_outdated i3lock-color "$VERSION" "$(bootstrap::latest_tag "$REPO")"
}
