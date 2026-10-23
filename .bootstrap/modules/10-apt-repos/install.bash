# Adds the apt repositories that publish codium and brave-browser, the installs vscodium.com and
# brave.com/linux document.
readonly SOURCES_DIR=/etc/apt/sources.list.d
readonly KEYRINGS_DIR=/usr/share/keyrings

if ! has gpg; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gnupg
fi

if [[ ! -f $SOURCES_DIR/vscodium.sources ]]; then
  curl -fsSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor | sudo dd status=none of="$KEYRINGS_DIR/vscodium-archive-keyring.gpg"
  sudo tee "$SOURCES_DIR/vscodium.sources" > /dev/null << SOURCES
Types: deb
URIs: https://download.vscodium.com/debs
Suites: vscodium
Components: main
Architectures: amd64 arm64
Signed-by: $KEYRINGS_DIR/vscodium-archive-keyring.gpg
SOURCES
fi

if [[ ! -f $SOURCES_DIR/brave-browser-release.sources ]]; then
  sudo curl -fsSLo "$KEYRINGS_DIR/brave-browser-archive-keyring.gpg" \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  sudo curl -fsSLo "$SOURCES_DIR/brave-browser-release.sources" \
    https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
fi
