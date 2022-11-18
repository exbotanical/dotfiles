ROOT_DIR="$(dirname "$(readlink -f $BASH_SOURCE)")"
APP_DIR="$ROOT_DIR/../.config/bash/apps"

source "$ROOT_DIR/shpec_util.bash"

describe 'cmd'
  describe 'base64'
    alias setup='source "$APP_DIR/openssl/cmd.bash"'

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
end_describe
