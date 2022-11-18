ROOT_DIR="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$ROOT_DIR/shpec_util.bash"
source "$ROOT_DIR/../.config/bash/settings/cmd.bash"

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
end_describe
