RootDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

source "$RootDir/../../.test/shpec_utils.bash"

Fixtures=$(mktemp -d)
export OS_RELEASE="$Fixtures/os-release"
export PACKAGES_DIR="$Fixtures/packages"
source "$RootDir/../lib.bash"

describe 'bootstrap lib'
  describe bootstrap::distro
    it 'maps os-release to a supported distro'
      cases=(
        'ID=arch|arch'
        'ID=ubuntu VERSION_ID=24.04|ubuntu'
        'ID=amzn VERSION_ID=2023|al2023'
      )

      for spec in "${cases[@]}"; do
        IFS='|' read -r release expected <<<"$spec"
        printf '%s\n' $release > "$OS_RELEASE"
        assert equal "$expected" "$(bootstrap::distro)"
      done
    ti

    it 'rejects unsupported distros'
      for release in 'ID=amzn VERSION_ID=2' 'ID=fedora VERSION_ID=40'; do
        printf '%s\n' $release > "$OS_RELEASE"
        (bootstrap::distro) 2> /dev/null
        assert unequal 0 $?
      done
    ti
  end_describe

  describe bootstrap::default_profile
    it 'runs AL2023 headless and other distros as desktops'
      for spec in 'al2023|headless' 'arch|desktop' 'ubuntu|desktop'; do
        IFS='|' read -r distro expected <<<"$spec"
        assert equal "$expected" "$(bootstrap::default_profile "$distro")"
      done
    ti
  end_describe

  describe bootstrap::packages
    setup () {
      mkdir -p "$PACKAGES_DIR/ubuntu"
      printf 'shared-base\n' > "$PACKAGES_DIR/apt.base.txt"
      printf '# comment\n\ndistro-base  # trailing\n' > "$PACKAGES_DIR/ubuntu/apt.base.txt"
      printf 'distro-desktop\n' > "$PACKAGES_DIR/ubuntu/apt.desktop.txt"
    }
    alias setup=setup

    it 'combines shared and distro lists for the profile, without comments or blank lines'
      cases=(
        'headless|shared-base distro-base'
        'desktop|shared-base distro-base distro-desktop'
      )

      for spec in "${cases[@]}"; do
        IFS='|' read -r profile expected <<<"$spec"
        actual=$(DISTRO=ubuntu PROFILE=$profile bootstrap::packages apt | tr '\n' ' ')
        assert equal "$expected" "${actual% }"
      done
    ti

    it 'prints nothing for a manager without lists'
      assert equal '' "$(DISTRO=ubuntu PROFILE=desktop bootstrap::packages dnf)"
    ti
  end_describe

  describe bootstrap::selected
    it 'applies ONLY and SKIP'
      cases=(
        '||41-rust|0'
        '41-rust,42-go||42-go|0'
        '41-rust||42-go|1'
        '|43-haskell,44-ocaml|44-ocaml|1'
        '|43-haskell|41-rust|0'
      )

      for spec in "${cases[@]}"; do
        IFS='|' read -r only skip name expected <<<"$spec"
        ONLY=$only SKIP=$skip bootstrap::selected "$name"
        assert equal "$expected" $?
      done
    ti
  end_describe
end_describe

rm -rf "$Fixtures"
