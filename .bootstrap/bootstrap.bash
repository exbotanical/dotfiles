#!/usr/bin/env bash
# Installs every prerequisite of the dotfiles, then runs `make install`. Safe to re-run.
#
# Usage: .bootstrap/bootstrap.bash
#   PROFILE=desktop|headless  override the profile chosen for the distro
#   ONLY=10-apt-repos,...     run only these modules
#   SKIP=43-haskell,...       skip these modules
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.bash"

# Runs a module file in its own bash process, so errexit applies inside it even though the
# caller tests its status.
run_module_file () {
  bash -euo pipefail -c 'source "$1"; source "$2"' _ "$BOOTSTRAP_DIR/lib.bash" "$1"
}

run_module () {
  local dir=${1%/}
  local name=${dir##*/}

  if ! bootstrap::selected "$name"; then
    log "[-] $name (not selected)"
    return
  fi
  if ! run_module_file "$dir/detect.bash"; then
    log "[-] $name (not applicable)"
    return
  fi

  log "[+] $name"
  run_module_file "$dir/install.bash" || die "[!] $name failed; rerun it with ONLY=$name"
}

# Refreshes the sudo timestamp until the bootstrap exits, so long builds do not prompt again.
keep_sudo_alive () {
  sudo -v
  while sleep 60; do
    sudo -n true
    kill -0 "$$" 2> /dev/null || exit
  done &
  trap 'kill $! 2> /dev/null' EXIT
}

main () {
  export DISTRO PROFILE
  DISTRO=$(bootstrap::distro)
  PROFILE=${PROFILE:-$(bootstrap::default_profile "$DISTRO")}
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.ghcup/bin:/usr/local/go/bin:$PATH"

  log "[*] bootstrapping $DISTRO ($PROFILE)"
  keep_sudo_alive

  local dir
  for dir in "$BOOTSTRAP_DIR"/modules/*/; do
    run_module "$dir"
  done
}

main
