# Many of these from Ted Lilley's "Bash Like a Developer" series
# See: https://www.binaryphile.com/bash/2018/07/26/approach-bash-like-a-developer-part-1-intro.html
support::interactive? () {
  [[ $- == *i* ]]
}

# sourced? returns true if the current file is being sourced
support::sourced? () {
  [[ ${FUNCNAME[1]} == source ]]
}

# defined? returns true if the argument is defined
support::defined? () {
  [[ -v "$1" ]]
}

support::present? () {
  [[ -n ${1:-} ]]
}

# extant? returns true if the argument is an available command
support::extant? () {
  type $1 &>/dev/null
}

# strict_mode toggles strict mode
support::strict_mode () {
  case "$1" in
    on)
      set -o errexit
      set -o errtrace
      set -o nounset
      set -o pipefail
      trap traceback ERR
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
support::debug_mode () {
  case "$1" in
    on) set -x  ;;
    off) set +x ;;
    *) echo 1   ;;
  esac
}

# globbing toggles globbing
support::globbing () {
  case $1 in
    on  ) set +o noglob;;
    off ) set -o noglob;;
  esac
}

support::splitspace () {
  case $1 in
    on  ) IFS=$' \t\n';;
    off ) IFS=$'\n'   ;;
  esac
}

# aliases toggles shell aliases
support::aliases () {
  case $1 in
    on  ) shopt -s expand_aliases;;
    off ) shopt -u expand_aliases;;
  esac
}

# traceback adds stack traces to bash ops
support::traceback () {
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

# Parse named options and positional arguments
# TODO: support short named args with or without whitespace
# TODO: support long named args with or without whitespace, with `=`
support::parseopts () {
  local defs_=$2
  local -n opts_=$3
  local -n posargs_=$4
  local -A flags_=()
  # A hash, indexed by an option pointing to its value
  local -A names_=()

  _err_=0
  set -- $1

  # Create a hash whose keys are the flag opts
  denormopts "$defs_" names_ flags_

  # Process multiple arguments, gathering resulting key=value pairs
  # into an array, which is passed back via indirection through ref_.
  # Stop parsing when encountering an argument that doesn't begin with a hyphen.
  while [[ ${1:-} == -?* ]]; do
    # -- signifies end of opts
    [[ $1 == -- ]] && {
      shift
      break
    }

    # Test whether the option is in the hash
    support::defined? names_[$1] || {
      _err_=1
      return
    }

    ! support::defined? flags_[$1]
    case $? in
      0 )
        opts_+=( ${names_[$1]}=$2 )
        shift
        ;;
      * ) opts_+=( ${names_[$1]}=1 );;
    esac
    shift
  done
  posargs_=( $@ )
}

denormopts () {
  local -n _names_=$2
  local -n _flags_=$3
  local IFS=$IFS
  local _defn_
  local _opt_

  for _defn_ in $1; do
    IFS=,
    set -- $_defn_
    IFS='|'

    for _opt_ in $1; do
      _names_[$_opt_]=$2
      support::present? ${3:-} && _flags_[$_opt_]=1
    done
  done
}
