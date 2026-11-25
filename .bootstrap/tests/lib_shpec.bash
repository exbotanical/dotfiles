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

  describe bootstrap::read_list
    it 'prints the names in every existing file, without comments or blank lines'
      printf '# head\n\na  # trailing\nb\n' > "$Fixtures/first.txt"
      printf 'c\n' > "$Fixtures/second.txt"
      actual=$(bootstrap::read_list "$Fixtures/first.txt" "$Fixtures/missing.txt" "$Fixtures/second.txt" | tr '\n' ' ')
      assert equal 'a b c' "${actual% }"
    ti
  end_describe

  describe bootstrap::inputs_checksum
    alias setup='dir=$(mktemp -d) || return; mkdir -p $dir/modules/10-x $dir/packages $dir/tests
      printf a > $dir/modules/10-x/install.bash; printf b > $dir/packages/apt.base.txt
      printf c > $dir/tests/lib_shpec.bash; before=$(bootstrap::inputs_checksum $dir)'
    alias teardown='rm -rf $dir'

    it 'changes when a module or a package list changes, and ignores the tests'
      printf changed > $dir/tests/lib_shpec.bash
      tests_only=$(bootstrap::inputs_checksum $dir)
      printf b2 > $dir/packages/apt.base.txt
      list=$(bootstrap::inputs_checksum $dir)
      printf a2 > $dir/modules/10-x/install.bash
      module=$(bootstrap::inputs_checksum $dir)
      [[ $tests_only == "$before" && $list != "$before" && $module != "$list" ]]
      assert equal 0 $?
    ti
  end_describe

  describe bootstrap::require_interface
    alias setup='dir=$(mktemp -d) || return'
    alias teardown='rm -rf $dir'

    it 'accepts every module in the repository'
      failed=$(for module in "$RootDir"/../modules/*/; do
        bootstrap::require_interface "${module%/}" 2> /dev/null || printf '%s ' "${module%/}"
      done)
      assert equal '' "$failed"
    ti

    it 'names each interface function a module does not define'
      printf 'module::applies () { :; }\n' > $dir/module.bash
      result=$(bootstrap::require_interface $dir 2>&1)
      assert equal "[!] $dir/module.bash does not define module::install module::outdated" "$result"
    ti
  end_describe

  describe bootstrap::newest_tag
    it 'prints the newest release in version order and skips prereleases'
      result=$(printf '%s\n' v0.9.1 v0.40.8 v0.41.0-rc1 v0.10.0 v0.40.10 | bootstrap::newest_tag)
      assert equal 'v0.40.10' "$result"
    ti
  end_describe

  describe bootstrap::report_outdated
    it 'reports a differing latest version and nothing for a current or unknown one'
      result=$(bootstrap::report_outdated a v1 v2; bootstrap::report_outdated b v1 v1; bootstrap::report_outdated c v1 '')
      assert equal 'a v1 -> v2' "$result"
    ti
  end_describe
end_describe

rm -rf "$Fixtures"
