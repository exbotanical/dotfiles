#!/usr/bin/env bash
#desc           :Bootstrap a new project template.
#author         :Matthew Zito
#===============================================================================
# shellcheck disable=SC2046,SC2048,SC2086
IFS=$'\n'

GITHUB_URL=https://github.com/exbotanical

TS_NPM_REPO=$GITHUB_URL/ts-npm-boilerplate
JS_NPM_REPO=$GITHUB_URL/js-npm-boilerplate
GO_REPO=$GITHUB_URL/go-lib-boilerplate
C_REPO=$GITHUB_URL/c-boilerplate
CLIB_REPO=$GITHUB_URL/clib-boilerplate

clib_setup_files () {
  # the include header
  local header=include/lib$proj.h

  # the include guard
  local incl_guard
  incl_guard=$(echo $proj | tr 'a-z' 'A-Z')_H

  # include header statement
  local incl_header
  incl_header="#include \"${header:4:${#header}}\""

  # create the main header file and...
  mkdir include
  touch $header

  # ...add the include guards therein
  cat > $header <<END
#ifndef $incl_guard
#define $incl_guard

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __cplusplus
}
#endif

#endif /* $incl_guard */
END
}

designate () {
  local proj=$1

  find . -type f -exec sed -i "s/<project>/$proj/g" {} \;
  sed -i "s/<year>/$(date +%Y)/" LICENSE
}

git_setup () {
  # Remove existing git dir
  rm -rf .git
  git init
}

setup () {
  local env=$1
  local proj=$2

  case $env in
    tsnpm )
      git clone --depth 1 $TS_NPM_REPO .
      designate $proj
      pnpm install
      ;;

    jsnpm )
      git clone --depth 1 $JS_NPM_REPO .
      designate $proj
      pnpm install
      ;;

    go )
      git clone --depth 1 $GO_REPO .
      designate $proj
      go mod init $proj
      ;;

    c )
      git clone --depth 1 $C_REPO .
      designate $proj
      ;;

    clib)
      git clone --depth 1 $CLIB_REPO .
      ;;
    * )
      echo -e "[-] No template exists for $env\n"
      exit 1
      ;;
  esac

  git_setup
}

main () {
  local env=$1
  local proj=$2

  local dir_name
  dir_name=$(basename $(pwd))

  echo -e "[+] Initializing a new $env environment for $proj in $dir_name...\n"

  setup $env $proj

  echo -e "[+] Project setup complete\n"
}

# stop here if being sourced
return 2>/dev/null

set -o errexit
set -o nounset

main $*
