#!/usr/bin/env bash

install () {
  local key='dependencies'
  local dep_type="${1:-whatever}"
  local install_cmd='install'

  if [ "$dep_type" = 'dev' ]; then
    key='devDependencies'
    install_cmd='install -D'
  fi

  echo "Checking $key..."

  declare deps=($(jq -r ".$key | keys[]" package.json | grep "$pattern" ||:))
  if [ -z "${deps[*]}" ]; then
    echo "No $key matching '$pattern' found."
  fi

  local did_anything=0
  for dep in "${deps[@]}"; do
    echo "Updating $dep to latest version..."
    npm $install_cmd "$dep@latest"
    did_anything=1
  done

  return $did_anything
}

main () {
  local did_anything=0
  local pattern="$1"
  declare deps

  if [ -z "$pattern" ]; then
    echo "Usage: $0 <pattern>"
    exit 1
  fi

  install
  [[ $? -eq 1 ]] && did_anything=1

  install 'dev'
  [[ $? -eq 1 ]] && did_anything=1

  if [ $did_anything -eq 1 ]; then
    echo 'All matching dependencies updated'
  fi
}

return 2>/dev/null

set -o errexit
set -o nounset

main $*
