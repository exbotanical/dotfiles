# Many of these from Ted Lilley's "Bash Like a Developer" series
# See: https://www.binaryphile.com/bash/2018/07/26/approach-bash-like-a-developer-part-1-intro.html
utils::interactive? () {
  [[ $- == *i* ]]
}

# sourced? returns true if the current file is being sourced
utils::sourced? () {
  [[ ${FUNCNAME[1]} == source ]]
}

# defined? returns true if the argument is defined
utils::defined? () {
  [[ -v "$1" ]]
}

# extant? returns true if the argument is an available command
utils::extant? () {
  type $1 &>/dev/null
}

# strict_mode toggles strict mode
utils::strict_mode () {
  case "$1" in
    on)
      set -o errexit
      set -o errtrace
      set -o nounset
      set -o pipefail
      trap 'utils::traceback' ERR
      ;;
    off)
      set +o errexit
      set +o errtrace
      set +o nounset
      set +o pipefail
      trap - ERR
      ;;
    *)
      echo 1
      ;;
  esac
}

# debug_mode toggles debug mode (xtrace)
utils::debug_mode () {
  case "$1" in
    on) set -x  ;;
    off) set +x ;;
    *) echo 1   ;;
  esac
}

# globbing toggles globbing
utils::globbing () {
  case $1 in
    on  ) set +o noglob;;
    off ) set -o noglob;;
  esac
}

# splitspace toggles splitting on spaces
utils::splitspace () {
  case $1 in
    on  ) IFS=$' \t\n';;
    off ) IFS=$'\n'   ;;
  esac
}

# aliases toggles shell aliases
utils::aliases () {
  case $1 in
    on  ) shopt -s expand_aliases;;
    off ) shopt -u expand_aliases;;
  esac
}

# traceback adds stack traces to bash ops
utils::traceback () {
  local -i rc=$?
  set +o xtrace
  local -i frame=0
  local IFS
  local expression
  local result

  IFS=' '
  echo $'\nTraceback:'
  while result=$(caller $frame); do
    set -- $result
    (( frame == 0 )) && {
      printf -v expression '%s s/^[[:space:]]*// p' "$1"
      echo -n '  Command: '
      sed -n "$expression" "$3"
    }
    echo "  $3:$1:in '$2'"
    frame+=1
  done
  printf '  Exit status: %s\n\n' $rc
  return $rc
} >&2

# filter applies a unary function on a stream of values,
# returning only those values for which the function evaluates to true
utils::filter () {
  local item

  while read -r item; do
    $1 $item && echo $item
  done
}

# file? returns true if the provided argument is a file
utils::file? () {
  [[ -r $1 ]]
}

# dir? returns true if the provided argument is a directory
utils::dir? () {
  [[ -d $1 ]]
}

# macos? returns true if the host os is macos
utils::macos? () {
  [[ "$OSTYPE" == "darwin"* ]]
}

# vscodium? returns true if the current shell is being emulated inside of vscodium's terminal
utils::vscodium? () {
  [[ "$TERM_PROGRAM" == 'vscode' ]]
}
