# shellcheck disable=SC2157,SC2203
if [[ utils::macos? ]]; then
  utils::file? /opt/homebrew/bin/go
else
  utils::file? /usr/local/go/bin/go
fi
