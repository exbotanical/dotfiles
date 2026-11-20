RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_utils.bash"
source "$RootDir/../.config/bash/scripts/wifi_autoconnect.bash"

describe 'wifi_autoconnect'
  describe 'patterns'
    alias setup='dir=$(mktemp -d) || return'
    alias teardown='rm -rf $dir'

    it 'prints pattern lines without comments and blank lines'
      printf '%s\n' '# phones' '' 'Home*' 'Phone' > $dir/list
      result=$(patterns $dir/list)
      assert equal $'Home*\nPhone' "$result"
    ti

    it 'prints a last line that has no trailing newline'
      printf 'Home' > $dir/list
      result=$(patterns $dir/list)
      assert equal 'Home' "$result"
    ti

    it 'prints nothing for a missing file'
      result=$(patterns $dir/absent)
      assert equal '' "$result"
    ti
  end_describe

  describe 'autoconnect_value'
    it 'prints yes for listed profiles, no for the rest, and nothing for unmanaged ones'
      AUTOCONNECT=('Home*' 'Phone')
      UNMANAGED=('Corp (*)')
      result=$(for name in 'Home 5G' 'Phone' 'Phone 2' 'Corp (lan)' 'Cafe'; do
        printf '%s=%s\n' "$name" "$(autoconnect_value "$name")"
      done)
      assert equal $'Home 5G=yes\nPhone=yes\nPhone 2=no\nCorp (lan)=\nCafe=no' "$result"
    ti

    it 'prints no for every profile when nothing is unmanaged'
      AUTOCONNECT=('Home')
      UNMANAGED=()
      result=$(autoconnect_value 'Cafe')
      assert equal 'no' "$result"
    ti
  end_describe

  describe 'wifi_profiles'
    it 'prints Wi-Fi profile names only and unescapes colons'
      nmcli () {
        printf '%s\n' '802-11-wireless:Home' '802-3-ethernet:Wired' '802-11-wireless:Cafe\:5G'
      }
      result=$(wifi_profiles)
      assert equal $'Home\nCafe:5G' "$result"
    ti
  end_describe

  describe 'main'
    alias setup='dir=$(mktemp -d) || return; mkdir $dir/wifi; XDG_CONFIG_HOME=$dir'
    alias teardown='rm -rf $dir'

    it 'changes only profiles whose autoconnect differs and prints each change'
      printf '%s\n' 'Home' 'Phone' > $dir/wifi/autoconnect
      printf '%s\n' 'Corp*' > $dir/wifi/unmanaged
      nmcli () {
        # Other test files change IFS, and $* joins the arguments with its first character.
        local IFS=' '
        case $* in
          '-t -f TYPE,NAME connection show')
            printf '802-11-wireless:%s\n' Home Phone Cafe 'Corp lan'
            ;;
          '-g connection.autoconnect connection show id Home') printf 'no\n' ;;
          '-g connection.autoconnect connection show id Phone') printf 'yes\n' ;;
          '-g connection.autoconnect connection show id Cafe') printf 'yes\n' ;;
          'connection modify id '*) ;;
          *) return 1 ;;
        esac
      }
      sudo () { "$@"; }
      result=$(main)
      assert equal $'Home: no -> yes\nCafe: yes -> no' "$result"
    ti

    it 'exits nonzero when the autoconnect file lists no patterns'
      printf '# none yet\n' > $dir/wifi/autoconnect
      (main) 2> /dev/null
      assert equal 1 $?
    ti
  end_describe
end_describe
