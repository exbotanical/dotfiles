# parseopts parses positional, named, and flag arguments
parser::parseopts () {
  local defs_=$2
  local -n opts_=$3
  local -n posargs_=$4
  local -A flags_=()
  local -A names_=()

  _err_=0
  set -- $1
  denormopts "$defs_" names_ flags_

  while [[ ${1:-} == -?* ]]; do
    [[ $1 == -- ]] && {
      shift
      break
    }
    defined? names_[$1] || {
      _err_=1
      return
    }
    ! defined? flags_[$1]
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
      present? ${3:-} && _flags_[$_opt_]=1
    done
  done
}

defined? () {
  [[ -v "$1" ]]
}

present? () {
  [[ -n ${1:-} ]]
}
