# Installs the current Go release into /usr/local/go, where apps/go/detect.bash looks for it.
# go.dev/doc/install requires removing the old tree before extracting a new one.
readonly GO_ROOT=/usr/local/go

case $(uname -m) in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

latest=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n 1)
installed=$("$GO_ROOT/bin/go" env GOVERSION 2> /dev/null || true)
if [[ $installed == "$latest" ]]; then
  log "[=] $installed"
  exit 0
fi

archive=$(mktemp)
trap 'rm -f "$archive"' EXIT
curl -fsSLo "$archive" "https://go.dev/dl/$latest.linux-$arch.tar.gz"
sudo rm -rf "$GO_ROOT"
sudo tar -C "${GO_ROOT%/*}" -xzf "$archive"
