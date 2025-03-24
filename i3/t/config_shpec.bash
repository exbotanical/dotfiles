RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_util.bash"

describe 'i3 config'
  it 'validates the config'
    if [[ "$OSTYPE" == 'linux-gnu' ]]; then
      i3 -C -c $RootDir/../.config/i3/config
      assert equal $? 0
    else
      echo 'Skipping i3 test as it can only run on linux machines'
    fi
  ti
end_describe
