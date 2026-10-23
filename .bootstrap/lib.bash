#!/usr/bin/env bash
# Shared helpers for bootstrap.bash and its modules.

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

# Prints every package in the lists for a package manager that apply to $DISTRO and $PROFILE,
# one per line. A desktop profile includes the base lists. Lists may contain blank lines and
# '#' comments.
bootstrap::packages () {
  local manager=$1 profile file
  local profiles=(base)
  [[ $PROFILE == desktop ]] && profiles+=(desktop)

  for profile in "${profiles[@]}"; do
    for file in "$PACKAGES_DIR/$manager.$profile.txt" "$PACKAGES_DIR/$DISTRO/$manager.$profile.txt"; do
      [[ -f $file ]] && sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$file"
    done
  done
  return 0
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
