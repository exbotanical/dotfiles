#!/usr/bin/env bash
#desc           :A simple TODO manager.
#author         :Matthew Zito
#===============================================================================
# shellcheck disable=SC2086,SC2048


panic () {
  local exit_status=$1

  shift

  echo "[-] ERROR: $*" >&2
  exit $exit_status
}

verify_args () {
  if (( $# < 1 )); then
    panic $E_ARGS 'Insufficient arguments'
  fi
}

check_todo_file () {
  if [[ ! -e $TODO_FILE ]];then
    panic $E_FILENOTFOUND "File $TODO_FILE does not exist. Add a TODO to create one."
  fi
}

logo () {
  cat <<END
   ██                 ██
  ░██                ░██
 ██████  ██████   ██████  ██████
░░░██  ░██░░░░██░██░░░██░██   ░██
  ░██  ░██   ░██░██  ░██░██   ░██
  ░██  ░░██████ ░░██████░░██████
   ░░    ░░░░░░   ░░░░░░  ░░░░░░

END
}

usage () {
  logo

  cat <<END
Create or delete a TODO.

Usage:
  Add a TODO: $0 [--add] [-a] <TODO text>
  Delete a TODO: $0 [--delete] [-d] <TODO lineno>

Examples:
  $0 -a download the new bjork record
  $0 -d 1
  $0 -d 5,10 # delete TODOs 5 - 10

END
  exit 1
}

add_todo () {
  local todo=$*

  echo - $todo >> $TODO_FILE
  echo [+] Added TODO: \"$todo\"
}

delete_todo () {
  local todo_num=$1

  sed -e $todo_num'd' -i $TODO_FILE
}

show_todos () {
  logo
  nl -b a $TODO_FILE
}

main () {
  local cmd=$1

  shift # remove cmd so we can pass along variadic args

  case "$cmd" in
    add | --add | -a)
      verify_args $*
      add_todo $*
      ;;

    delete | --delete | -d )
      verify_args $*
      check_todo_file
      delete_todo $1
      ;;

    show | --show | -s )
      check_todo_file
      show_todos
      ;;

    * )
      usage
      ;;
  esac
}

IFS=$'\n'

E_FILENOTFOUND=2
E_ARGS=88
TODO_FILE=/tmp/.todo

main $*
