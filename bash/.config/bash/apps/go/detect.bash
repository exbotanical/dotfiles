# shellcheck disable=SC2157,SC2203
if [[ support::macos? ]]; then
  support::file? /opt/homebrew/bin/go
else
  support::file? /usr/local/go/bin/go
fi
