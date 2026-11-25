#!/usr/bin/env bash
# Records the bootstrap inputs checksum after a successful run, or warns when the inputs differ
# from the recorded ones, which means bootstrap has packages or modules this machine lacks. The
# check never fails, and bootstrap.bash skips it for the `make install` it runs itself.
#
# Usage: stamp.bash write|check
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.bash"

main () {
  local stamp
  stamp=$(bootstrap::stamp_file)

  case ${1:-} in
    write)
      mkdir -p "${stamp%/*}"
      bootstrap::inputs_checksum "$BOOTSTRAP_DIR" > "$stamp"
      ;;
    check)
      [[ -n ${DOTFILES_BOOTSTRAPPING:-} ]] && return 0
      [[ $(cat "$stamp" 2> /dev/null) == "$(bootstrap::inputs_checksum "$BOOTSTRAP_DIR")" ]] && return 0
      printf '%s\n' '[!] bootstrap inputs changed since its last run on this machine; run make bootstrap' >&2
      ;;
    *) die 'usage: stamp.bash write|check' ;;
  esac
}

main "$@"
