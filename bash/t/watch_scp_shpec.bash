RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/shpec_util.bash"
source "$RootDir/../.config/bash/scripts/watch_scp.bash"

describe 'watch_scp'
  describe 'list'
    alias setup='dir=$(mktemp -d) || return'
    alias teardown='rm -rf $dir'

    it 'lists files matching a pattern list separated by newlines'
      touch $dir/file.txt $dir/file.html $dir/file.csv
      result=$(list $dir '*.txt|*.html')
      assert equal $'file.html\nfile.txt' "$result"
    ti
  end_describe

  describe transfer
    it 'calls scp'
      REMOTE=dest
      DIR=dir
      stub_command scp 'echo $@'

      result=$(transfer <<<$'one.txt\ntwo.txt')
      assert equal "$DIR/one.txt $REMOTE\n$DIR/two.txt $REMOTE" "$result"
    ti
  end_describe


  describe 'newitems'
    it 'outputs a newline-separated list of items whick appear in a second list but are not in the first'
      result=$(newitems $'apple\nbanana\ncherry' $'apple\ndate\nelderberry')
      assert equal $'date\nelderberry' "$result"
    ti

    it 'reports nothing when the second list is empty and the first is not'
      result=$(newitems one '' | while read -r item; do echo triggered; done)
      assert equal '' "$result"
    ti
  end_describe
end_describe
