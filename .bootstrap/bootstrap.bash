#!/usr/bin/env bash
# Installs every prerequisite for dotfiles, runs `make install`, and then warns about pinned
# versions that have a newer upstream release. This entire script is idempotent and is therefore
# safe to re-run.
#
# Each .bootstrap/modules/NN-name/module.bash defines the functions in MODULE_INTERFACE (lib.bash):
#   module::applies   returns 0 when the module applies to this machine
#   module::install   installs what is missing and skips what is already installed
#   module::outdated  prints one line per pinned version with a newer upstream release
#
# Usage: .bootstrap/bootstrap.bash [outdated]
#   outdated                  only report the pinned versions with a newer upstream release
#   PROFILE=desktop|headless  override the profile chosen for the distro
#   ONLY=10-apt-repos,...     run only these modules
#   SKIP=43-haskell,...       skip these modules
#   MACHINE=<name>            select the machine (x11/.config/machines/<name>.env) used by ~/.xprofile
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.bash"

# Runs function $2 of module directory $1 in its own bash process;
# errexit therefore applies therein although the caller tests its status.
call_module () {
  bash -euo pipefail -c 'source "$1"; source "$2/module.bash"; "$3"' _ "$BOOTSTRAP_DIR/lib.bash" "$1" "$2"
}

# Returns 0 when module directory $1 is selected and applies, and logs why it is skipped otherwise.
module_runs () {
  local name=${1##*/}

  if ! bootstrap::selected "$name"; then
    log "[-] $name (not selected)"
    return 1
  fi

  if ! call_module "$1" module::applies; then
    log "[-] $name (not applicable)"
    return 1
  fi
}

install_module () {
  local name=${1##*/}
  module_runs "$1" || return 0
  log "[+] $name"
  call_module "$1" module::install || die "[!] $name failed; rerun it with ONLY=$name"
}

# Warns about each line module directory $1 reports as outdated. A check that fails, e.g. offline,
# is reported and does not stop the run.
report_outdated () {
  local name=${1##*/} lines line
  bootstrap::selected "$name" && call_module "$1" module::applies || return 0

  if ! lines=$(call_module "$1" module::outdated); then
    log "[?] $name: could not check for newer versions"
    return 0
  fi
  while IFS= read -r line; do
    [[ -n $line ]] && log "[!] outdated: $name: $line"
  done <<< "$lines"
  return 0
}

# Refreshes the sudo timestamp until this script exits to prevent re-prompts in the likely event of a long build.
keep_sudo_alive () {
  sudo -v

  while sleep 60; do
    sudo -n true
    kill -0 "$$" 2> /dev/null || exit
  done &

  trap 'kill $! 2> /dev/null' EXIT
}

main () {
  local command=${1:-install} dir
  local -a modules
  [[ $command == install || $command == outdated ]] || die 'usage: bootstrap.bash [outdated]'

  export DISTRO PROFILE
  DISTRO=$(bootstrap::distro)
  PROFILE=${PROFILE:-$(bootstrap::default_profile "$DISTRO")}
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.ghcup/bin:/usr/local/go/bin:$PATH"

  # stamp.bash check skips the warning for the make install that 90-dotfiles runs.
  export DOTFILES_BOOTSTRAPPING=1

  for dir in "$BOOTSTRAP_DIR"/modules/*/; do
    modules+=("${dir%/}")
    bootstrap::require_interface "${dir%/}" || exit 1
  done

  if [[ $command == install ]]; then
    log "[*] bootstrapping $DISTRO ($PROFILE)"
    keep_sudo_alive
    for dir in "${modules[@]}"; do
      install_module "$dir"
    done
    "$BOOTSTRAP_DIR/stamp.bash" write
  fi

  log "[*] checking pinned versions"
  for dir in "${modules[@]}"; do
    report_outdated "$dir"
  done
}

main "$@"
