RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_util.bash"

source "$RootDir/../.config/bash/src/cmd.bash"

describe 'cmd'
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

  describe 'cmd_out'
    alias setup="dir=$(mktemp -d) && stub_command some_cmd '>&2 echo error && echo ok'"
    alias teardown='unstub_command some_cmd'

    it 'pipes command stdout and stderr to two respective files'
      pushd $dir

      cmd_out 'some_cmd'
      assert file_present stdout.txt
      assert file_present stderr.txt
      assert equal $(cat ./stdout.txt) 'ok'
      assert equal $(cat ./stderr.txt) 'error'

      rm -r "$dir"
    ti
  end_describe

  describe 'cmd_out_clean'
    it 'removes the stdout and stderr files'
      pushd $dir

      cmd_out 'some_cmd'
      assert file_present stdout.txt
      assert file_present stderr.txt

      cmd_out_clean
      assert file_absent stdout.txt
      assert file_absent stderr.txt

      rm -r "$dir"
    ti
  end_describe
end_describe
