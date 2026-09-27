RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_utils.bash"

UtilsLib="$RootDir/../.config/bash/lib/utils.bash"

source "$UtilsLib"

describe 'utils'
  describe 'interactive?'
    it 'returns false because these tests are not in an interactive shell'
      utils::interactive?
      # result=$(utils::interactive? || echo 1)
      assert equal 1 $?
    ti
  end_describe

  describe 'sourced?'
    # shellcheck disable=SC2154
    alias setup='file=$(mktemp) || return; printf '\''source "%s"\nutils::sourced?'\'' "$UtilsLib" > "$file"'
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

  describe 'defined?'
    it 'returns true if the variable is defined'
      defined_var=1
      utils::defined? $defined_var
      assert equal 0 $?
    ti

    it 'returns false if the variable is undefined'
      utils::defined? $undefined_var
      assert unequal 0 $?
    ti
  end_describe

  describe 'extant?'
    it 'returns true if the provided entity exists'
      fn () {
        :
      }
      utils::extant? fn
      assert equal 0 $?
    ti

    it 'returns false if the provided entity does not exist'
      utils::extant? fn
      assert unequal 0 $?
    ti
  end_describe

  describe 'strict mode'
    it 'sets errexit'
      utils::strict_mode on
      [[ $- == *e* ]]
      assert equal 0 $?
    ti

    it 'unsets errexit'
      set -o errexit
      utils::strict_mode off
      [[ $- == *e* ]]
      assert unequal 0 $?
    ti

    it 'sets nounset'
      utils::strict_mode on
      [[ $- == *u* ]]
      assert equal 0 $?
    ti

    it 'unsets nounset'
      set -o nounset
      utils::strict_mode off
      [[ $- == *u* ]]
      assert unequal 0 $?
    ti

    it 'sets pipefail'
      utils::strict_mode on
      [[ :$SHELLOPTS: == *:pipefail:* ]]
      assert equal 0 $?
    ti

    it 'unsets pipefail'
      set -o pipefail
      utils::strict_mode off
      [[ :$SHELLOPTS: == *:pipefail:* ]]
      assert unequal 0 $?
    ti
  end_describe

  describe 'debug mode'
    it 'sets xtrace'
      set -x
      utils::debug_mode on
      [[ $- == *x* ]]
      assert equal 0 $?
    ti

    it 'unsets xtrace'
      set +x
      utils::debug_mode off
      [[ $- == *x* ]]
      assert unequal 0 $?
    ti
  end_describe

  describe 'globbing'
    it 'sets globbing'
      set -o noglob
      utils::globbing on
      [[ $- == *f* ]]
      assert equal 1 $?
    ti

    it 'unsets globbing'
      set +o noglob
      utils::globbing off
      [[ $- == *f* ]]
      assert equal 0 $?
    ti
  end_describe

  describe 'splitspace'
    it 'sets IFS to split on newlines'
      utils::splitspace off
      text="Welcome to the jungle"
      read -a arr <<< "$text"
      assert equal "$arr" "Welcome to the jungle"
    ti

    it 'sets IFS to split on spaces'
      utils::splitspace on
      text="Welcome to the jungle"
      read -a arr <<< "$text"
      assert equal "$arr" "Welcome"
    ti
  end_describe

  describe 'aliases'
    it 'turns on aliases'
      shopt -u expand_aliases
      utils::aliases on
      alias hello='echo var'
      assert equal "$(hello)" 'var'
    ti

    it 'turns off aliases'
      utils::aliases off
      alias hello='echo var'
      assert unequal "$(hello)" 'var'
    ti
  end_describe

  describe 'traceback'
    it 'forwards the return code of the triggering event'
      (
        set -o errexit
        trap utils::traceback ERR
        false # trigger errexit
      ) 2>/dev/null

      assert equal 1 $?
    ti

    it 'outputs a header'
      IFS=$'\n'
      result=$(utils::traceback 2>&1)

      assert equal Traceback: $result
    ti

    it 'outputs an indented exit status on the last line'
      IFS=$'\n'
      set -- $(utils::traceback 2>&1)

      assert equal '  Exit status: 0' ${!#}
    ti

    it 'outputs the offending source line'
      IFS=$'\n'
      set -- $(utils::traceback 2>&1)

      assert equal '  Command: set -- $(utils::traceback 2>&1)' $2
    ti

    it 'prints the erroring file'
      IFS=$'\n'
      set -- $(utils::traceback 2>&1)
      IFS=:
      set -- $3
      echo "$1"
      # TODO: fix, where indentation changes by loc
      assert equal 'utils_shpec.bash' "$(basename $1)"
    ti

    it "prints the line number"
      IFS=$'\n'
      set -- $(utils::traceback 2>&1)
      IFS=:
      set -- $3
      [[ $2 == *[[:digit:]] ]]
      assert equal 0 $?
    ti

    it "prints the function"
      IFS=$'\n'
      set -- $(utils::traceback 2>&1)
      IFS=:
      set -- $3
      assert equal "in 'source'" $3
    ti

    it "prints a top-level function two levels deep"
      fn () {
        utils::traceback
      }
      IFS=$'\n'
      set -- $(fn 2>&1)
      IFS=:
      set -- $4
      assert equal "in 'source'" $3
    ti
  end_describe

  describe 'filter'
    it 'filters a stream against a unary predicate'
      utils::splitspace off

      even? () { (( $1 % 2 == 0 )) ;}
      integers=( 1 2 3 4 )
      result=$(echo "${integers[*]}" | utils::filter even?)
      expected=( 2 4 )
      assert equal "${expected[*]}" "$result"
    ti
  end_describe

  describe 'file?'
    alias teardown='rm "$file"'

    it 'returns true if the provided argument is a file'
      file=$(mktemp)
      utils::file? $file
      assert equal 0 $?
    ti

    it 'returns true if the provided argument is a directory (also a file)'
      file=$(mktemp -d)
      utils::file? $file
      assert equal 0 $?
    ti

    it 'returns false if the provided argument is not a file'
      file=$(echo hi)
      utils::file? $file
      assert unequal 0 $?
    ti
  end_describe

  describe 'dir?'
    alias teardown='rm "$file"'

    it 'returns true if the provided argument is a directory'
      file=$(mktemp -d)
      utils::dir? $file
      assert equal 0 $?
    ti

    it 'returns false if the provided argument is not a directory'
      file=$(mktemp)
      utils::dir? $file
      assert unequal 0 $?
    ti
  end_describe

  describe 'rmdir_exists'
    it 'removes a directory that exists and returns success'
      test_dir=$(mktemp -d)
      utils::rmdir_exists "$test_dir"
      assert equal 0 $?
      [[ ! -d "$test_dir" ]]
      assert equal 0 $?
    ti

    it 'returns failure when directory does not exist'
      nonexistent_dir="/tmp/nonexistent_$(date +%s)"
      utils::rmdir_exists "$nonexistent_dir"
      assert equal 1 $?
    ti

    it 'returns failure for a file (only works on directories)'
      test_file=$(mktemp)
      utils::rmdir_exists "$test_file"
      assert equal 1 $?
      [[ -f "$test_file" ]]
      assert equal 0 $?
      rm "$test_file"
    ti

    it 'returns failure for empty argument'
      utils::rmdir_exists ""
      assert equal 1 $?
    ti

    it 'returns failure for no argument'
      utils::rmdir_exists
      assert equal 1 $?
    ti
  end_describe
end_describe
