#!/usr/bin/env bash
# Shared utilities for bootstrap.bash and its modules.

readonly BOOTSTRAP_DIR="$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR="${BOOTSTRAP_DIR%/*}"
readonly PACKAGES_DIR="${PACKAGES_DIR:-$BOOTSTRAP_DIR/packages}"
readonly OS_RELEASE="${OS_RELEASE:-/etc/os-release}"

log () {
  printf '%s\n' "$*"
}

die () {
  printf '%s\n' "$@" >&2
  exit 1
}

has () {
  command -v "$1" &> /dev/null
}

# Prints arch, ubuntu, or al2023 for the running distro.
bootstrap::distro () {
  local id version
  id=$(. "$OS_RELEASE" && printf '%s' "${ID:-}")
  version=$(. "$OS_RELEASE" && printf '%s' "${VERSION_ID:-}")

  case "$id:$version" in
    arch:*) printf 'arch' ;;
    ubuntu:*) printf 'ubuntu' ;;
    amzn:2023) printf 'al2023' ;;
    *) die "unsupported distro: $id $version" ;;
  esac
}

bootstrap::default_profile () {
  case "$1" in
    al2023) printf 'headless' ;;
    *) printf 'desktop' ;;
  esac
}

# Prints the package names in the list files (one per line)
# sans '#' comments, trailing whitespace, or blank lines.
# Missing files are skipped.
bootstrap::read_list () {
  local file
  for file; do
    [[ -e $file ]] && sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$file"
  done
  return 0
}

# Prints every package (one per line) in the lists for a package manager that apply to $DISTRO and $PROFILE.
# A `desktop` profile includes the base lists. Lists may contain blank lines and '#' comments.
bootstrap::packages () {
  local manager=$1 profile
  local profiles=(base)
  [[ $PROFILE == desktop ]] && profiles+=(desktop)

  for profile in "${profiles[@]}"; do
    bootstrap::read_list "$PACKAGES_DIR/$manager.$profile.txt" "$PACKAGES_DIR/$DISTRO/$manager.$profile.txt"
  done
}

# Returns 0 when $1 appears in the comma-separated list $2.
bootstrap::listed () {
  [[ ",$2," == *",$1,"* ]]
}

# Returns 0 when the module named $1 is selected by $ONLY and $SKIP.
bootstrap::selected () {
  local name=$1
  if [[ -n ${ONLY:-} ]] && ! bootstrap::listed "$name" "$ONLY"; then
    return 1
  fi
  ! bootstrap::listed "$name" "${SKIP:-}"
}

# Prints one checksum of every file under the bootstrap directory $1 except its tests: the
# modules, the package lists, and the scripts that run them decide what bootstrap installs.
bootstrap::inputs_checksum () {
  (cd "$1" && find . -type f -not -path './tests/*' -print0 | LC_ALL=C sort -z | xargs -0 sha256sum) \
    | sha256sum | cut -d' ' -f1
}

# Prints the file that records the inputs checksum of the last bootstrap run that succeeded.
bootstrap::stamp_file () {
  printf '%s/dotfiles/bootstrap.sha256' "${XDG_STATE_HOME:-$HOME/.local/state}"
}
