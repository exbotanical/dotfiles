# TODO: source lib/support.bash if not already
PreexistingFunctions=$(compgen -A function | sort)

# login? returns true if the global `ENV_SET` flag has not been set, indicating
# this is the first shell login
init::login? () {
  ! (( ENV_SET ))
}

# Set the `ENV_SET` flag to indicate we've logged in
init::set_login () {
  export ENV_SET=1
}

# export exports the key value pair, only using the value $2 if the
# export key is not already set.
init::export () {
  export $1=${!1:-$2}
}

# contains? returns true if $1 contains $2
init::contains? () { (
  IFS=:
  [[ "$IFS$1$IFS" == *"$IFS$2$IFS"* ]]
) }

# append_path appends the given argument to the PATH
init::append_path () {
  init::contains? "$PATH" $1 && return
  declare -g PATH=$PATH:$1
}

# prepend_path prepends the given argument to the PATH
init::prepend_path () {
  init::contains? "$PATH" $1 && return
  declare -g PATH=$1:${PATH}
}

# export_builtin sets the variable $1 to the first verified builtin
# $2.. are variadic args that may or may not be builtin commands. export_builtin
# exports the first valid builtin and returns.
init::export_builtin () {
  local ref=$1; shift
  local builtin_cmd

  for builtin_cmd; {
    ! type -p $builtin_cmd &>/dev/null && continue
    export $ref=$(type -p $builtin_cmd)
    return
  }
}

# source? sources the provided argument if it is a file
init::source? () {
  support::file? $1 && source $1
}

init::load_app? () {
  local dir=$1
  local detect_file=$dir/detect.bash

  # If it has a detect file, invoke it
  support::file? $detect_file && {
    source $detect_file
    return
  }

  # Ensure the directory name matches an actual executable
  type $dir &>/dev/null
}

# list_dir lists the directory's contents without newlines
init::list_dir () { (
  local items=()

  cd $1
  support::globbing on
  items=( * )
  echo "${items[*]}"
) }

# Write arguments to stdout only if the debug flag is set
init::debug () {
  ! (( INIT_DEBUG_MODE )) && return

  echo -e "[$(date +"%T.%3N")] $1"
}

# Toggle the debug flag
init::toggle_debug () {
  (( INIT_DEBUG_MODE ^= 1));:
  export INIT_DEBUG_MODE
}

# Diff the pre-existing functions against the ones declared in this file
# shellcheck disable=SC2034
EphemeralFunctions=( $(comm -13 <(echo "$PreexistingFunctions") <(compgen -A function | sort)) )
# Add the functions declared in this file to EphemeralVars for subsequent cleanup
EphemeralVars+=( EphemeralVars EphemeralFunctions )
# Cleanup
unset -v PreexistingFunctions
