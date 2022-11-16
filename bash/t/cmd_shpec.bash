shopt -s expand_aliases

alias it='(_shpec_failures=0; alias setup &>/dev/null && { setup; unalias setup; alias teardown &>/dev/null && trap teardown EXIT ;}; it'
# shellcheck disable=SC2154
alias ti='return "$_shpec_failures"); (( _shpec_failures += $?, _shpec_examples++ ))'
alias end_describe='end; unalias setup teardown 2>/dev/null'

source "$(dirname "$(readlink -f "BASH_SOURCE")")/../.config/bash/cmd.bash"

describe 'cmd'

  describe 'base64'
    it 'encodes to and decodes from base64'
      test_str='string'
      base64_str=$(base64 -e "$test_str")
      result=$(base64 -d "$base64_str")

      # sanity check
      assert unequal "$test_str" "$base64_str"
      assert equal "$result" "$test_str"
    ti

    it 'returns a help message if argument missing'
      result=$(base64 -d)
      assert equal "$result" "[!] Option -d requires an argument"
    ti
  end_describe

  describe 'bak'
    alias setup='file=$(mktemp) || return'
    # shellcheck disable=SC2154
    alias teardown='rm "$file"; rm $file*.bak'

    it 'creates a timestamped backup'
      stubbed_date='202211141256'
      stub_command "date" "echo '$stubbed_date'"

      # sanity check
      assert file_absent "$file-$stubbed_date.bak"

      bak "$file"
      assert file_present "$file-$stubbed_date.bak"

      unstub_command "date"
    ti
  end_describe

end_describe
