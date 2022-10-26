#!/usr/bin/env bash
#desc           :Bootstrap a new project template.
#author         :Matthew Zito
#===============================================================================

clib_setup_files () {
  # the include header
  local header=src/$proj.h

  # source file
  local source=src/$proj.c

  # the include guard
  local incl_guard=$(echo $proj | tr '[a-z]' '[A-Z]')_H

  # include header statement
  local incl_header="#include \"$(echo ${header:4:${#header}})\""

  # create the main header file and...
  touch $source
  touch $header

  # ...add the include guards therein
  cat > $header <<END
#ifndef $incl_guard
#define $incl_guard

#endif /* $incl_guard */
END

  cat > $source <<END
$incl_header
END
}

designate () {
  local proj=$1

  find . -type f -exec sed -i "s/<project>/"$proj"/g" {} \;
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
      git clone $TS_NPM_REPO .
      designate $proj
      pnpm install
      ;;

    jsnpm )
      git clone $JS_NPM_REPO .
      designate $proj
      pnpm install
      ;;

    go )
      git clone $GO_REPO .
      designate $proj
      go mod init $proj
      ;;

    c )
      git clone $C_REPO .
      designate $proj
      ;;

    clib )
      git clone $C_LIB_REPO .
      designate $proj
      clib_setup_files
      ;;

    * )
      echo -e "[-] No template exists for $env\n"
      exit 1
      ;;
  esac

  git_setup
}

main () {
  local dir_name=$(basename $(pwd))
  local env=$1
  local proj=$2

  echo -e "[+] Initializing a new $env environment for $proj in $dir_name...\n"

  setup $env $proj

  echo -e "[+] Project setup complete\n"
}

IFS=$'\n'

GITHUB_URL=https://github.com/exbotanical

TS_NPM_REPO=$GITHUB_URL/ts-npm-boilerplate
JS_NPM_REPO=$GITHUB_URL/js-npm-boilerplate
GO_REPO=$GITHUB_URL/go-lib-boilerplate
C_REPO=$GITHUB_URL/c-boilerplate
C_LIB_REPO=$GITHUB_URL/dll-boilerplate

# stop here if being sourced
return 2>/dev/null

set -o errexit
set -o nounset

main $*
