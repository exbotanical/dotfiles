# Ubuntu installs Brave as brave-browser, while Arch (AUR brave-bin) installs it as brave.
# The i3 and dunst configs launch brave, so link it on Ubuntu.
readonly TARGET=/usr/bin/brave-browser
readonly LINK=/usr/bin/brave

[[ -x $TARGET ]] || die "$TARGET not found; install Brave first"
if [[ -e $LINK && ! -L $LINK ]]; then
  die "$LINK exists and is not a symlink"
fi
if [[ $(readlink "$LINK" || true) == "$TARGET" ]]; then
  log "[=] $LINK"
  exit 0
fi
sudo ln -sfn "$TARGET" "$LINK"
