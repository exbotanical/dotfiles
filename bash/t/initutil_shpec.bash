RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_util.bash"

init_utils_lib="$RootDir/../.config/bash/lib/init_utils.bash"

describe 'init_utils'
  describe 'globals'
    it 'sets a global variable to cache all defined functions for cleanup'
      # sanity check
      [[ -v EphemeralFunctions ]]
      assert equal 1 $?
      source "$init_utils_lib"
      [[ -v EphemeralFunctions ]]
      assert equal 0 $?
    ti

    it 'updates the global EphemeralVars variable to cache any defined variables for cleanup'
      EphemeralVars=( 1 )
      source "$init_utils_lib"
      # assert not unset
      [[ -v EphemeralVars ]]
      assert equal 0 $?
      assert equal 3 ${#EphemeralVars[@]}
    ti

    alias setup='source $init_utils_lib'

    it 'unsets the PreexistingFunctions list'
      [[ -v PreexistingFunctions ]]
      assert equal 1 $?
    ti

    it 'only includes namespaced functions in the EphemeralFunctions list'
      count=$( printf -- '%s\n' "${EphemeralFunctions[@]}" | grep -vc '^init.*' )
      assert equal 0 "$count"
    ti

  end_describe

  describe 'login?'
    it 'state is not manipulated by /etc/profile or system var'
      ret=$(env -i bash <<END
      source "$init_utils_lib"
      init::login? && echo 1
END
  )
      assert equal 1 "$ret"
    ti

    it 'state is persistent'
      export ENV_SET=0
      source "$init_utils_lib"
      init::login?
      assert equal 0 $?
      init::set_login
      init::login?
      assert equal 1 $?
    ti
  end_describe

  describe 'export'
    it 'exports the existing value if already exported'
      TestVariable=1
      [[ "${TestVariable@a}" == *x*  ]]
      assert equal 1 $?

      export TestVariable

      source "$init_utils_lib"
      init::export TestVariable 2
      assert equal 1 "$TestVariable"

      [[ "${TestVariable@a}" == *x*  ]]
      assert equal 0 $?
    ti

    it 'exports the new value if not already exported'
      source "$init_utils_lib"
      init::export TestVariable 2
      assert equal 2 "$TestVariable"
    ti
  end_describe

  describe 'contains?'
    alias setup='source $init_utils_lib'

    it 'returns true if the first value contains the second'
      init::contains? "h:ell:o" "ell"
      assert equal 0 $?
    ti

    it 'returns false if the first value does not contain the second'
      init::contains? "el:hello:o" "ell"
      assert unequal 0 $?
    ti
  end_describe

  describe 'PATH helpers'
    it 'appends the value to the PATH if not already extant'
      test_val='TESTVALUE'

      [[ $PATH == *"$test_val" ]];
      assert equal 1 $?

      source "$init_utils_lib"
      init::append_path "$test_val"

      [[ $PATH == *"$test_val" ]];
      assert equal 0 $?
    ti

    it 'ignores the append value if already extant in the PATH'
      test_val='TESTVALUE'

      source "$init_utils_lib"

      init::append_path "$test_val"
      init::append_path "$test_val"

      [[ $PATH == *"$test_val:$test_val"* ]];
      assert equal 1 $?
    ti

    it 'prepends the value to the PATH if not already extant'
      test_val='TESTVALUE'

      [[ $PATH == "$test_val"* ]];
      assert equal 1 $?

      source "$init_utils_lib"
      init::prepend_path "$test_val"

      [[ $PATH == "$test_val"* ]];
      assert equal 0 $?
    ti

    it 'ignores the prepend value if already extant in the PATH'
      test_val='TESTVALUE'

      source "$init_utils_lib"

      init::prepend_path "$test_val"
      init::prepend_path "$test_val"

      [[ $PATH == *"$test_val:$test_val" ]];
      assert equal 1 $?
    ti
  end_describe

  describe 'export_builtin'
    alias setup='source $init_utils_lib'

    it 'exports the first viable builtin command value'
      builtin_path=$(type -p ls)
      init::export_builtin TESTVAR 'blablabla' 'doesntexist' 'ls' 'vim' 'pwd'
      assert equal "$builtin_path" "$TESTVAR"
    ti

    it 'doesnt export the value at all if no builtin extant in args'
      init::export_builtin TESTVAR 'blablabla' 'doesntexist' 'NOPEEE'
      [[ -v TESTVAR ]]
      assert equal 1 $?
    ti
  end_describe

  describe 'source?'
    alias setup='source $init_utils_lib'

    it 'sources a the provided argument only if it is a file'
      file=$(mktemp)
      printf 'echo 2' > "$file"
      assert equal 2 $(init::source? "$file")
      rm "$file"
    ti

    it 'returns early if the provided argument is not a file'
      file=$(mktemp -d)
      $(init::source? "$file")
      assert equal 1 $?
      rmdir "$file"
    ti
  end_describe

  describe 'list_dir'
    alias setup='source $init_utils_lib'

    it 'enumerates the directory contents as a single line'
      IFS=' '
      dir=$(mktemp -d)
      pushd "$dir"
      touch {a..z}
      result=$(init::list_dir "$dir")
      expected=$(echo {a..z})
      assert equal "$expected" "$result"
      rm -r "$dir"
    ti
  end_describe

  describe 'order_by_dependencies'
    alias setup='source $init_utils_lib'

    it 'orders apps by dependencies'
      utils::splitspace off
      utils::globbing off

      dir=$(mktemp -d)
      pushd "$dir"
      mkdir {a..d}
      touch {a..d}/deps

      echo 'd' > a/deps
      echo 'b' > d/deps

      apps=$(init::list_dir $dir | init::order_by_dependencies)

      arr=($apps)

      assert equal 'a' ${arr[2]}
      assert equal 'b' ${arr[0]}
      assert equal 'c' ${arr[3]}
      assert equal 'd' ${arr[1]}

      rm -r "$dir"
    ti
  end_describe
end_describe
