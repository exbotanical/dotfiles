#!/usr/bin/env bash
# Builds the integ test image for each distro and runs .dev/integ-test.bash in a
# throwaway container, all distros in parallel. Exits non-zero when any distro fails.
#
# Usage: .dev/run-integ.bash [ubuntu] [arch]   (default: both)
set -euo pipefail

readonly REPO_DIR="$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOCKERFILE="$REPO_DIR/.dev/Dockerfile"
readonly DISTROS=(ubuntu arch)

assert_known_distro () {
  local distro=$1 known
  for known in "${DISTROS[@]}"; do
    [[ $distro == "$known" ]] && return 0
  done
  printf 'unknown distro: %s (expected: %s)\n' "$distro" "${DISTROS[*]}" >&2
  return 1
}

run_distro () {
  local distro=$1
  local image="dotfiles-integ:$distro"

  docker build --build-arg "DISTRO=$distro" --target integ --file "$DOCKERFILE" \
    --tag "$image" "$REPO_DIR"
  docker run --rm "$image"
}

prefix () {
  local distro=$1 line
  while IFS= read -r line; do
    printf '[%s] %s\n' "$distro" "$line"
  done
}

main () {
  local distros=("$@")
  ((${#distros[@]})) || distros=("${DISTROS[@]}")

  local distro
  local -A pids=()
  for distro in "${distros[@]}"; do
    assert_known_distro "$distro"
    { run_distro "$distro" 2>&1 | prefix "$distro"; } &
    pids[$distro]=$!
  done

  local failed=()
  for distro in "${distros[@]}"; do
    wait "${pids[$distro]}" || failed+=("$distro")
  done

  if ((${#failed[@]})); then
    printf 'integ test failed on: %s\n' "${failed[*]}" >&2
    return 1
  fi
  printf 'integ test passed on: %s\n' "${distros[*]}"
}

main "$@"
