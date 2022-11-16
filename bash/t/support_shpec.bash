support_lib="$(dirname "$(readlink -f "BASH_SOURCE")")/../.config/bash/lib/support.bash"
source "$support_lib"

support::aliases on

alias it='(_shpec_failures=0; alias setup &>/dev/null && { setup; unalias setup; alias teardown &>/dev/null && trap teardown EXIT ;}; it'
# shellcheck disable=SC2154
alias ti='return "$_shpec_failures"); (( _shpec_failures += $?, _shpec_examples++ ))'
alias end_describe='end; unalias setup teardown 2>/dev/null'

describe 'support'
  describe 'sourced?'
    # shellcheck disable=SC2154
    alias setup='file=$(mktemp) || return; printf '\''source "%s"\nsupport::sourced?'\'' "$support_lib" > "$file"'
    alias teardown='rm "$file"'

    it 'returns true when in a file being sourced'
      (source "$file")
      assert equal 0 $?
    ti

    it 'returns false when the file is executed'
      chmod 775 "$file"
      "$file"
      assert unequal 0 $?
    ti
  end_describe

  describe 'strict mode'
    it 'sets errexit'
      support::strict_mode on
      [[ $- == *e* ]]
      assert equal 0 $?
    ti

    it 'unsets errexit'
      set -o errexit
      support::strict_mode off
      [[ $- == *e* ]]
      assert unequal 0 $?
    ti

    it 'sets nounset'
      support::strict_mode on
      [[ $- == *u* ]]
      assert equal 0 $?
    ti

    it 'unsets nounset'
      set -o nounset
      support::strict_mode off
      [[ $- == *u* ]]
      assert unequal 0 $?
    ti

    it 'sets pipefail'
      support::strict_mode on
      [[ :$SHELLOPTS: == *:pipefail:* ]]
      assert equal 0 $?
    ti

    it 'unsets pipefail'
      set -o pipefail
      support::strict_mode off
      [[ :$SHELLOPTS: == *:pipefail:* ]]
      assert unequal 0 $?
    ti
  end_describe

  describe 'debug mode'
    it 'sets xtrace'
      set -x
      support::debug_mode on
      [[ $- == *x* ]]
      assert equal 0 $?
    ti

    it 'unsets xtrace'
      set +x
      support::debug_mode off
      [[ $- == *x* ]]
      assert unequal 0 $?
    ti
  end_describe

  describe 'traceback'
    it 'forwards the return code of the triggering event'
      (
        set -o errexit
        trap support::traceback ERR
        false # trigger errexit
      ) 2>/dev/null

      assert equal 1 $?
    ti

    it 'outputs a header'
      IFS=$'\n'
      result=$(support::traceback 2>&1)

      assert equal Traceback: $result
    ti

    it 'outputs an indented exit status on the last line'
      IFS=$'\n'
      set -- $(support::traceback 2>&1)

      assert equal '  Exit status: 0' ${!#}
    ti

    it 'outputs the offending source line'
      IFS=$'\n'
      set -- $(support::traceback 2>&1)

      assert equal '  Command: set -- $(support::traceback 2>&1)' $2
    ti

    it 'prints the erroring file'
      IFS=$'\n'
      set -- $(support::traceback 2>&1)
      IFS=:
      set -- $3
      assert equal support_shpec.bash $(basename $1)
    ti

    it "prints the line number"
      IFS=$'\n'
      set -- $(support::traceback 2>&1)
      IFS=:
      set -- $3
      [[ $2 == *[[:digit:]] ]]
      assert equal 0 $?
    ti

    it "prints the function"
      IFS=$'\n'
      set -- $(support::traceback 2>&1)
      IFS=:
      set -- $3
      assert equal "in 'source'" $3
    ti

    it "prints a top-level function two levels deep"
      fn () {
        support::traceback
      }
      IFS=$'\n'
      set -- $(fn 2>&1)
      IFS=:
      set -- $4
      assert equal "in 'source'" $3
    ti
  end_describe

  describe 'parseopts'
    it 'returns a short flag'
      defs=( -o,o_flag,f  )
      args=( -o           )
      support::parseopts "${args[*]}" "${defs[*]}" options posargs
      assert equal o_flag=1 $options
    ti

    it 'returns with _err_=1 if the argument is undefined'
      defs=( -o,o_flag,f  )
      args=( --other      )
      support::parseopts "${args[*]}" "${defs[*]}" options posargs
      assert equal 1 $_err_
    ti

    it 'returns a named argument'
      defs=( --option,option_val  )
      args=( --option sample      )
      support::parseopts "${args[*]}" "${defs[*]}" options posargs
      assert equal option_val=sample $options
    ti

    it "returns a named argument and a flag"
      defs=(
        --option,option_val
        -p,p_flag,f
      )
      args=( --option sample -p )
      support::parseopts "${args[*]}" "${defs[*]}" options posargs
      expecteds=(
        option_val=sample
        p_flag=1
      )
      assert equal "${expecteds[*]}" "${options[*]}"
    ti

    it 'stops when it encounters a non-option'
      defs=( --option,option_val  )
      args=( --option sample -    )
      support::parseopts "${args[*]}" "${defs[*]}" options posargs
      assert equal option_val=sample $options
    ti

    it 'stops when it encounters --'
      defs=(
        --option,option_val
        -p,p_flag,f
      )
      args=( --option sample -- -p )
      support::parseopts "${args[*]}" "${defs[*]}" options posargs
      assert equal option_val=sample $options
    ti

    it 'returns positional arguments'
      defs=( -o,o_flag,f  )
      args=( -o one two   )
      support::parseopts "${args[*]}" "${defs[*]}" options posargs
      expecteds=( one two )
      assert equal "${expecteds[*]}" "${posargs[*]}"
    ti
  end_describe
end_describe
