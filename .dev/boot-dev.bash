#!/usr/bin/env bash
# Builds the dev sandbox image and opens an interactive shell in a throwaway container,
# with the repo mounted at the dev user's ~/dotfiles.
#
# Usage: .dev/boot-dev.bash [ubuntu|arch]   (default: ubuntu)
set -euo pipefail

readonly REPO_DIR="$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DOCKERFILE="$REPO_DIR/.dev/Dockerfile"

main () {
  local distro=${1:-ubuntu}
  local image="dotfiles-dev:$distro"

  docker build --build-arg "DISTRO=$distro" --target dev --file "$DOCKERFILE" \
    --tag "$image" "$REPO_DIR"
  docker run --rm -it --volume "$REPO_DIR:/home/dev/dotfiles" "$image"
}

main "$@"
