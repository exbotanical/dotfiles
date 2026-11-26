#!/usr/bin/env bash
set -euo pipefail

readonly REPO="$HOME/dotfiles"
readonly INIT_FILE="$HOME/.config/bash/init.bash"
readonly SCRIPTS_DIR="$REPO/bash/.config/bash/scripts"
# Modules that take several minutes to compile or are otherwise large (e.g. gigabytes).
# These are skipped during the integ tests. They nevertheless have at least some unit test coverage.
readonly HEAVY_MODULES=30-aur,43-haskell,45-cargo,61-eww
# Bootstrap installs only the packages required by the modules under test.
# The full package list is not installed; it is instead verified against the upstream via `assert_packages_exist`.
readonly FIXTURE_PACKAGES_DIR="$REPO/.dev/packages"
readonly LISTS_DIR="$REPO/.bootstrap/packages"
readonly LIB="$REPO/.bootstrap/lib.bash"
readonly AUR_RPC=https://aur.archlinux.org/rpc/v5/info
# systemd is not the init in the container, so install_root runs stubs that record the reload calls.
readonly STUB_DIR="$HOME/.cache/integ-stubs"
readonly STUB_LOG="$STUB_DIR/calls.log"

log () {
  printf '[integ] %s\n' "$*"
}

fail () {
  printf '[integ] FAIL: %s\n' "$*" >&2
  exit 1
}

install_all () {
  log 'make bootstrap'
  SKIP="$HEAVY_MODULES" PACKAGES_DIR="$FIXTURE_PACKAGES_DIR" make -C "$REPO" bootstrap
  install_root
}

# sudo resets PATH, so the stub directory is put first on the PATH it passes to make.
install_root () {
  : > "$STUB_LOG"
  log 'sudo make install_root'
  sudo env PATH="$STUB_DIR:$PATH" make -C "$REPO" install_root
}

# Writes systemctl and sysctl stubs that append their name and arguments to STUB_LOG and exit 0.
write_reload_stubs () {
  local name
  mkdir -p "$STUB_DIR"
  for name in systemctl sysctl; do
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s $*" >> %q\n' "$name" "$STUB_LOG" > "$STUB_DIR/$name"
    chmod +x "$STUB_DIR/$name"
  done
}

assert_dir () {
  [[ -d $1 ]] || fail "expected directory $1"
}

assert_file () {
  [[ -f $1 ]] || fail "expected file $1"
}

# Asserts that $1 is a read-only regular file that sources $2.
assert_rc_stub () {
  local rc=$1 init=$2
  [[ -f $rc && ! -L $rc && ! -w $rc ]] || fail "expected $rc to be a read-only regular file"
  grep -qxF "source \"\$HOME${init#"$HOME"}\"" "$rc" || fail "expected $rc to source $init"
}

assert_resolves_into_repo () {
  local path=$1
  [[ $(readlink -f "$path") == "$REPO"/* ]] || fail "expected $path to resolve into $REPO"
}

assert_install_state () {
  log 'asserting install state'
  assert_dir "$HOME/.local/bin"
  assert_dir "$HOME/.cache/vim"
  # shellcheck source=../x11/.config/theme.env
  source "$REPO/x11/.config/theme.env"
  assert_dir "$HOME/.themes/$GTK_THEME"
  assert_dir "$HOME/.local/share/icons/$ICON_THEME"
  assert_dir "$HOME/.icons/$CURSOR_THEME"
  assert_file "$HOME/.config/machine"
  assert_rc_stub "$HOME/.bashrc" "$INIT_FILE"
  assert_rc_stub "$HOME/.bash_profile" "$INIT_FILE"
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
  cmp -s /etc/issue "$REPO/root/etc/issue" || fail "expected /etc/issue to be a copy of $REPO/root/etc/issue"
}

# Asserts that the last install_root run made exactly the calls $1, one per line, to the stubs.
assert_reload_calls () {
  local expected=$1 calls
  calls=$(< "$STUB_LOG")
  [[ $calls == "$expected" ]] \
    || fail "expected install_root to call [${expected//$'\n'/; }], got [${calls//$'\n'/; }]"
}

# Asserts that install_root reloaded systemd and sysctl after it installed the root package, and
# that a rerun, in which every file is current, reloads neither.
assert_root_reloads () {
  log 'asserting install_root reloads only after a change'
  assert_reload_calls $'systemctl daemon-reload\nsysctl --quiet --system'
  install_root
  assert_reload_calls ''
}

# Starts bash with the given flags on a pseudo-terminal and asserts that init.bash loads with no output.
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

# Asserts that an interactive login copies every script into ~/.local/bin.
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
  for path in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.local/bin"/* "$REPO/startpage/bundle.js" "$REPO/startpage/startpage.html"; do
    printf 'file %s %s\n' "$path" "$(sha256sum < "$path")"
  done
  printf 'dir %s\n' "$HOME/.cache/vim"
  printf 'hooksPath %s\n' "$(git -C "$REPO" config --local core.hooksPath)"
  printf 'worktree %s\n' "$(git -C "$REPO" status --porcelain | sha256sum)"
}

# Prints the sorted names in the real desktop lists for the manager $2 on the distro $1.
listed_packages () {
  PACKAGES_DIR=$LISTS_DIR bash -c 'source "$1"; DISTRO=$2 PROFILE=desktop bootstrap::packages "$3"' \
    _ "$LIB" "$1" "$2" | LC_ALL=C sort -u
}

# Fails when the AUR lacks a name in the AUR list. Skips the check when the AUR is unreachable.
assert_aur_packages_exist () {
  local -a names args=()
  local name response missing
  mapfile -t names < <(listed_packages arch aur)
  for name in "${names[@]}"; do
    args+=(--data-urlencode "arg[]=$name")
  done

  if ! response=$(curl -fsS --get "${args[@]}" "$AUR_RPC"); then
    log "skipping the AUR name check: $AUR_RPC is unreachable"
    return
  fi
  missing=$(LC_ALL=C comm -23 <(printf '%s\n' "${names[@]}") \
    <(jq -r '.results[].Name' <<< "$response" | LC_ALL=C sort -u))
  [[ -z $missing ]] || fail "not in the AUR: ${missing//$'\n'/ }"
}

# Fails when the repository package names $3 lack a name in the real lists for the manager $2 on
# the distro $1.
assert_in_repositories () {
  local missing
  missing=$(LC_ALL=C comm -23 <(listed_packages "$1" "$2") <(LC_ALL=C sort -u <<< "$3"))
  [[ -z $missing ]] || fail "not in the $1 repositories: ${missing//$'\n'/ }"
}

# Fails when the distro's repositories lack a name in the real package lists. 20-packages has
# synced the package databases, and 10-apt-repos has added the Ubuntu repositories the lists use.
assert_packages_exist () {
  local distro
  distro=$(bash -c 'source "$1"; bootstrap::distro' _ "$LIB")
  log "checking the $distro package names"
  case $distro in
    arch)
      assert_in_repositories arch pacman "$(pacman -Slq)"
      assert_aur_packages_exist
      ;;
    ubuntu) assert_in_repositories ubuntu apt "$(apt-cache pkgnames)" ;;
  esac
}

prepare_home () {
  mkdir -p "$HOME/.config/gtk-3.0"
}

main () {
  prepare_home
  write_reload_stubs
  install_all
  assert_repo_unchanged
  assert_install_state
  assert_root_state
  assert_root_reloads
  assert_packages_exist

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
