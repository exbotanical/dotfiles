#!/usr/bin/env bash
#
# Runs `make TARGET` in each DIR whose Makefile defines TARGET and skips the others. `make -q`
# exits 2 both for a missing target and for a broken Makefile, so only make's "No rule to make
# target" message counts as missing; any other error stops the run.
#
# Usage: each-package.bash TARGET DIR...

set -euo pipefail

die () {
  printf '%s\n' "$@" >&2
  exit 1
}

main () {
  (($# >= 1)) || die 'usage: each-package.bash TARGET DIR...'
  local -r target=$1
  shift

  local dir err status
  for dir; do
    status=0
    err=$(make -s -C "$dir" -q "$target" 2>&1 > /dev/null) || status=$?
    if ((status == 2)); then
      [[ $err == *"No rule to make target '$target'"* ]] && continue
      die "$dir: $err"
    fi
    make -C "$dir" "$target" || die "make -C $dir $target failed"
  done
}

main "$@"
