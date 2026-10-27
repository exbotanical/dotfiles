#!/usr/bin/env bash
#
# Installs each program in GLOBALS globally, at the version pinned in this package's
# package-lock.json, so the global program matches the plugins the fallback configs load
# from this package's node_modules. nvm keeps one global folder per Node version, so rerun
# `make -C npm` after switching versions.

set -euo pipefail

readonly GLOBALS=(prettier)

die () {
  printf '%s\n' "$@" >&2
  exit 1
}

main () {
  command -v npm > /dev/null || die 'npm not found; install node, then run make -C npm'
  cd -- "$(dirname "${BASH_SOURCE[0]}")" || die 'cannot enter the npm package directory'

  local name version
  for name in "${GLOBALS[@]}"; do
    version=$(node -p "require('./package-lock.json').packages['node_modules/$name'].version") \
      || die "no locked version for $name"
    npm ls -g "$name@$version" > /dev/null || npm i -g "$name@$version" || die "npm i -g $name@$version failed"
  done
}

main "$@"
