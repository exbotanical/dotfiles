RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"
TestRoot=$(mktemp -d)
export SOULSEEK_DIR=$TestRoot/soulseek
LIB=$TestRoot/Music

source "$RootDir/../../.test/shpec_utils.bash"
source "$RootDir/../.config/bash/apps/soulseek/scripts/soulseek_share.bash"

# Lists the links in the share as "relative path -> target", sorted, one per line.
share_links () {
  local link
  while IFS= read -r -d '' link; do
    printf '%s -> %s\n' "${link#"$SHARE_DIR"/}" "$(readlink "$link")"
  done < <(find "$SHARE_DIR" -type l -print0) | sort
}

# A fake library of three albums: two by Nurse With Wound, one of them live, and one by the Godz.
beet () {
  case $1 in
    config) printf 'directory: %s\n' "$LIB" ;;
    ls)
      shift 3
      case "$*" in
        'albumartist:Nurse With Wound') printf '%s\n' "$LIB/Nurse With Wound/Chance (1979)" "$LIB/Nurse With Wound/Live (1984)" ;;
        'album::(?i)live') printf '%s\n' "$LIB/Nurse With Wound/Live (1984)" ;;
        'albumartist:Godz album::^Contact') printf '%s\n' "$LIB/The Godz/Contact High (1966)" ;;
        albumartist:Flagged) printf '%s\n' "$LIB/Flagged/Video (2001)" ;;
        bad*) return 1 ;;
      esac
      ;;
  esac
}

# A fake soulseek_check: every album folder under $LIB/Flagged holds one failing file, video.mp4,
# unless a --skip glob matches it. Exits with CHECK_STATUS when that is set.
soulseek_check () {
  local -a globs=()
  local dir glob status=0
  while [[ $1 == --skip ]]; do
    globs+=("$2")
    shift 2
  done
  shift
  [[ -n ${CHECK_STATUS:-} ]] && return "$CHECK_STATUS"
  for dir; do
    [[ $dir == "$LIB/Flagged/"* ]] || continue
    for glob in "${globs[@]}"; do
      [[ $dir/video.mp4 == $glob ]] && continue 2
    done
    printf '%s/video.mp4: type: neither audio nor artwork\n' "$dir"
    status=1
  done
  return "$status"
}

describe 'soulseek_share'
  describe 'query_words'
    it 'splits a query line the way a shell would'
      result=$(for line in 'albumartist:"Nurse With Wound"' 'albumartist:Godz album::^Contact' "label:'A B' , label:C"; do
        query_words "$line" | tr '\0' '|'
        printf '\n'
      done)
      assert equal $'albumartist:Nurse With Wound|\nalbumartist:Godz|album::^Contact|\nlabel:A B|,|label:C|' "$result"
    ti
  end_describe

  describe 'main'
    alias setup='rm -rf "$SOULSEEK_DIR"; mkdir -p "$SHARE_DIR"'

    it 'shares exactly the allowed albums, minus those a ! line matches'
      printf '%s\n' '# comment' '' 'albumartist:"Nurse With Wound"' 'albumartist:Godz album::^Contact' '!album::(?i)live' > "$ALLOWLIST"
      main > /dev/null
      assert equal "Nurse With Wound/Chance (1979) -> $LIB/Nurse With Wound/Chance (1979)"$'\n'"The Godz/Contact High (1966) -> $LIB/The Godz/Contact High (1966)" "$(share_links)"
    ti

    it 'removes links to albums no longer allowed and keeps regular files'
      printf '%s\n' 'albumartist:Godz album::^Contact' > "$ALLOWLIST"
      mkdir -p "$SHARE_DIR/Old Artist"
      ln -s "$LIB/Old Artist/Gone (1970)" "$SHARE_DIR/Old Artist/Gone (1970)"
      printf 'notes\n' > "$SHARE_DIR/notes.txt"
      main > /dev/null
      [[ -f $SHARE_DIR/notes.txt && ! -e $SHARE_DIR/Old\ Artist ]]
      assert equal "0 The Godz/Contact High (1966) -> $LIB/The Godz/Contact High (1966)" "$? $(share_links)"
    ti

    it 'replaces a link that points at an album folder beets has since renamed'
      printf '%s\n' 'albumartist:Godz album::^Contact' > "$ALLOWLIST"
      mkdir -p "$SHARE_DIR/The Godz"
      ln -s "$LIB/The Godz/Contact High (old name)" "$SHARE_DIR/The Godz/Contact High (1966)"
      main > /dev/null
      assert equal "The Godz/Contact High (1966) -> $LIB/The Godz/Contact High (1966)" "$(share_links)"
    ti

    it 'changes nothing with -n'
      printf '%s\n' 'albumartist:"Nurse With Wound"' > "$ALLOWLIST"
      main -n > /dev/null
      assert equal '' "$(share_links)"
    ti

    it 'exits 1 when the allowlist is missing or beets rejects a query'
      result=$( (main) 2> /dev/null; printf '%s ' $?; printf 'bad query\n' > "$ALLOWLIST"; (main) > /dev/null 2>&1; printf '%s' $?)
      assert equal '1 1' "$result"
    ti

    it 'changes nothing and exits 1 when an album it would add fails the checks'
      printf '%s\n' 'albumartist:Godz album::^Contact' 'albumartist:Flagged' > "$ALLOWLIST"
      mkdir -p "$SHARE_DIR/Old Artist"
      ln -s "$LIB/Old Artist/Gone (1970)" "$SHARE_DIR/Old Artist/Gone (1970)"
      (main) > /dev/null 2>&1
      assert equal "1 Old Artist/Gone (1970) -> $LIB/Old Artist/Gone (1970)" "$? $(share_links)"
    ti

    it 'shares a failing album when --skip matches each failing file'
      printf '%s\n' 'albumartist:Flagged' > "$ALLOWLIST"
      main --skip '*/Video (2001)/*.mp4' > /dev/null
      assert equal "0 Flagged/Video (2001) -> $LIB/Flagged/Video (2001)" "$? $(share_links)"
    ti

    it 'does not check albums already in the share'
      printf '%s\n' 'albumartist:Flagged' > "$ALLOWLIST"
      mkdir -p "$SHARE_DIR/Flagged"
      ln -s "$LIB/Flagged/Video (2001)" "$SHARE_DIR/Flagged/Video (2001)"
      main > /dev/null
      assert equal "0 Flagged/Video (2001) -> $LIB/Flagged/Video (2001)" "$? $(share_links)"
    ti

    it 'runs no checks with -n'
      printf '%s\n' 'albumartist:Flagged' > "$ALLOWLIST"
      main -n > /dev/null
      assert equal 0 $?
    ti

    it 'exits 1 when soulseek_check itself fails'
      printf '%s\n' 'albumartist:Godz album::^Contact' > "$ALLOWLIST"
      (CHECK_STATUS=2 main) > /dev/null 2>&1
      assert equal "1 " "$? $(share_links)"
    ti

    it 'exits 2 on an unknown option or a --skip without a glob'
      result=$( (main -x) > /dev/null 2>&1; printf '%s ' $?; (main --skip) > /dev/null 2>&1; printf '%s' $?)
      assert equal '2 2' "$result"
    ti
  end_describe
end_describe

rm -rf "$TestRoot"
