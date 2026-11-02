RootDir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

source "$RootDir/../../.test/shpec_utils.bash"
source "$RootDir/../.config/machines/select.bash"

Fixtures=$(mktemp -d)

# Writes one profile per "name:default" pair in $1 into a temporary/generated fixture directory.
# Prints the fixture directory path.
make_profiles () {
  local dir pair
  dir=$(mktemp -d "$Fixtures/profiles.XXXXXX")
  for pair in $1; do
    if [[ ${pair#*:} == 1 ]]; then
      printf 'DEFAULT=1\n' > "$dir/${pair%:*}.env"
    else
      printf 'GTK_FONT=x\n' > "$dir/${pair%:*}.env"
    fi
  done
  printf '%s\n' "$dir"
}

describe 'machines_select'
  it 'selects the named profile, or the default with a report on stderr'
    cases=(
      'eve:1 work:0|work|work|quiet'
      'eve:1 work:0||eve|reported'
      'eve:1 work:0|foo|eve|reported'
      'eve:0 work:1||work|reported'
      'eve:0 work:0||eve|reported'
      'eve:1 work:1||eve|reported'
    )

    for spec in "${cases[@]}"; do
      IFS='|' read -r profiles selected expected stderr <<<"$spec"

      dir=$(make_profiles "$profiles")
      actual=$(machines_select "$dir" "$selected" 2> "$Fixtures/stderr")

      assert equal "$expected" "$actual"
      if [[ $stderr == quiet ]]; then
        assert equal 0 "$(wc -c < "$Fixtures/stderr")"
      else
        assert unequal 0 "$(wc -c < "$Fixtures/stderr")"
      fi
    done
  ti

  it 'fails when the directory has no profiles'
    machines_select "$(make_profiles '')" eve > /dev/null 2>&1
    assert unequal 0 $?
  ti
end_describe

rm -rf "$Fixtures"
