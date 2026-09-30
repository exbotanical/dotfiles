#!/usr/bin/env bash

PROGRAM=${PROGRAM:-npm}

install () {
  local key='dependencies'
  local dep_type="${1:-whatever}"
  local install_cmd='install'

  if [ "$dep_type" = 'dev' ]; then
    key='devDependencies'
    install_cmd='install -D'
  fi

  echo "Checking $key..."

  declare deps=($(jq -r ".$key | keys[]" package.json))
  if [ -z "${deps[*]}" ]; then
    echo "No deps found under $key."
  fi

  local did_anything=0
  for dep in "${deps[@]}"; do
    echo "Updating $dep to latest version..."
    $PROGRAM $install_cmd "$dep@latest"
    did_anything=1
  done

  return $did_anything
}

main () {
  local did_anything=0
  declare deps

  install
  [[ $? -eq 1 ]] && did_anything=1

  install 'dev'
  [[ $? -eq 1 ]] && did_anything=1

  if [ $did_anything -eq 1 ]; then
    echo 'All matching dependencies updated'
  fi
}

return 2> /dev/null

set -o errexit
set -o nounset

main $*
