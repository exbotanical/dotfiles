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
  (( $# < 1 )) && {
    panic $E_ARGS 'Insufficient arguments'
  }
}

check_todo_file () {
  [[ ! -e $TODO_FILE ]]&& {
    panic $E_FILENOTFOUND "File $TODO_FILE does not exist. Add a TODO to create one."
  }
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
  local progpath=$(basename $0)
  local progname=${progpath%.*}
  logo

  cat <<END
Create or delete a TODO.

Usage:
  Add a TODO: $progname [--add] [-a] <TODO text>
  Delete a TODO: $progname [--delete] [-d] <TODO lineno>
  List TODOs [--list] [-l]

Examples:
  $progname -a download the new bjork record
  $progname -d 1
  $progname -d 5,10 # delete TODOs 5 - 10

END
  exit 0
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

list_todos () {
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

    list | --list | -l )
      check_todo_file
      list_todos
      ;;

    * ) usage ;;
  esac
}

IFS=$'\n'

E_FILENOTFOUND=2
E_ARGS=88
TODO_FILE=~/.config/.todo

main $*
