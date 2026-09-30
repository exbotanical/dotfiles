#!/usr/bin/env bash
set -euo pipefail

readonly REPO="$HOME/dotfiles"
readonly INIT_FILE="$HOME/.config/bash/init.bash"
readonly SCRIPTS_DIR="$REPO/bash/.config/bash/scripts"

log () {
  printf '[integ] %s\n' "$*"
}

fail () {
  printf '[integ] FAIL: %s\n' "$*" >&2
  exit 1
}

install_all () {
  log 'make install'
  make -C "$REPO" install
  remove_root_conflicts
  log 'sudo make install_root'
  sudo make -C "$REPO" install_root
}

# Stow won't link files it does not own, so we remove any existing distro
# counterparts of the root package's files prior to running `install_root`.
remove_root_conflicts () {
  local path
  for path in /etc/issue; do
    if [[ -f $path && ! -L $path ]]; then
      log "removing the image's $path"
      sudo rm "$path"
    fi
  done
}

assert_dir () {
  [[ -d $1 ]] || fail "expected directory $1"
}

assert_file () {
  [[ -f $1 ]] || fail "expected file $1"
}

assert_link_to () {
  local link=$1 target=$2
  [[ -L $link && $(readlink "$link") == "$target" ]] \
    || fail "expected $link to link to $target, got '$(readlink "$link" || true)'"
}

assert_resolves_into_repo () {
  local path=$1
  [[ $(readlink -f "$path") == "$REPO"/* ]] || fail "expected $path to resolve into $REPO"
}

assert_install_state () {
  log 'asserting install state'
  assert_dir "$HOME/.local/bin"
  assert_dir "$HOME/.cache/vim"
  assert_link_to "$HOME/.bashrc" "$INIT_FILE"
  assert_link_to "$HOME/.bash_profile" "$INIT_FILE"
  assert_resolves_into_repo "$HOME/.gtkrc-2.0"
  assert_resolves_into_repo "$HOME/.config/gtk-3.0/settings.ini"
  assert_file "$REPO/startpage/bundle.js"
  assert_file "$REPO/startpage/startpage.html"
  assert_dir "$REPO/node_modules"
  [[ $(git -C "$REPO" config --local core.hooksPath) == .githooks ]] \
    || fail 'expected core.hooksPath to be .githooks'
}

assert_repo_unchanged () {
  local changes
  changes=$(git -C "$REPO" status --porcelain)
  [[ -z $changes ]] || fail "install changed files in the repo: $changes"
}

assert_root_state () {
  log 'asserting root install state'
  assert_resolves_into_repo /etc/issue
}

# Starts bash with the given flags on a pseudo-terminal and asserts init.bash loads with no output.
assert_shell_loads () {
  local flags=$1 output
  log "bash $flags loads cleanly"
  output=$(
    env -i HOME="$HOME" USER="$(id -un)" SHELL=/bin/bash TERM=xterm-256color LANG=C.UTF-8 \
      PATH=/usr/local/bin:/usr/bin:/bin \
      script --quiet --return --command "bash $flags -c 'type -t utils::interactive? > /dev/null'" /dev/null
  ) || fail "bash $flags exited non-zero: ${output//$'\r'/}"
  output=${output//$'\r'/}
  [[ -z $output ]] || fail "bash $flags wrote output: $output"
}

# Asserts that an interactive login copied every script into ~/.local/bin.
# See: bash/.config/bash/src/login.bash
assert_login_state () {
  log 'asserting login state'
  local script name
  for script in "$SCRIPTS_DIR"/*; do
    name=${script##*/}
    [[ -x "$HOME/.local/bin/${name%.*}" ]] || fail "expected executable ~/.local/bin/${name%.*}"
  done
}

# Prints the state this repo's install and login code produces such that two runs can be compared.
snapshot () {
  local path
  for path in "$HOME/.bashrc" "$HOME/.bash_profile"; do
    printf 'link %s -> %s\n' "$path" "$(readlink "$path")"
  done
  for path in "$HOME/.local/bin"/* "$REPO/startpage/bundle.js" "$REPO/startpage/startpage.html"; do
    printf 'file %s %s\n' "$path" "$(sha256sum < "$path")"
  done
  printf 'dir %s\n' "$HOME/.cache/vim"
  printf 'hooksPath %s\n' "$(git -C "$REPO" config --local core.hooksPath)"
  printf 'worktree %s\n' "$(git -C "$REPO" status --porcelain | sha256sum)"
}

prepare_home () {
  mkdir -p "$HOME/.config/gtk-3.0"
}

main () {
  prepare_home
  install_all
  assert_repo_unchanged
  assert_install_state
  assert_root_state

  assert_shell_loads -i
  assert_shell_loads -l
  assert_shell_loads -il
  assert_login_state

  log 'make unit_test'
  make -C "$REPO" unit_test

  local first second
  first=$(snapshot)
  log 'reinstalling'
  install_all
  assert_repo_unchanged
  assert_shell_loads -il
  second=$(snapshot)
  [[ $first == "$second" ]] \
    || fail "reinstall changed state: $(diff <(printf '%s\n' "$first") <(printf '%s\n' "$second") || true)"

  log 'all checks passed'
}

main
