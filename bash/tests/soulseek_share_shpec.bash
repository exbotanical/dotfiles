RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"
TestRoot=$(mktemp -d)
export SOULSEEK_DIR=$TestRoot/soulseek
LIB=$TestRoot/Music

source "$RootDir/../../.test/shpec_utils.bash"
source "$RootDir/../.config/bash/apps/soulseek/scripts/soulseek_share.bash"

# Prints the sorted, newline-delimited links in the share as "relative path -> target"
share_links () {
  local link
  while IFS= read -r -d '' link; do
    printf '%s -> %s\n' "${link#"$SHARE_DIR"/}" "$(readlink "$link")"
  done < <(find "$SHARE_DIR" -type l -print0) | sort
}

# A fake beets library: two albums by Nurse With Wound (one of them live), one by the Godz, one in
# Flagged, and albums in music_archive by Steve Reich and the Godz. As beets does, it lists every
# album for an empty query.
beet () {
  case $1 in
    config) printf 'directory: %s\n' "$LIB" ;;
    ls)
      shift 3
      case "$*" in
        '') printf '%s\n' "$LIB/Nurse With Wound/Chance (1979)" "$LIB/Nurse With Wound/Live (1984)" "$LIB/The Godz/Contact High (1966)" ;;
        'albumartist: Godz') printf '%s\n' "$LIB/The Godz/Contact High (1966)" ;;
        'albumartist:Nurse With Wound') printf '%s\n' "$LIB/Nurse With Wound/Chance (1979)" "$LIB/Nurse With Wound/Live (1984)" ;;
        'album::(?i)live') printf '%s\n' "$LIB/Nurse With Wound/Live (1984)" ;;
        'albumartist:Godz album::^Contact') printf '%s\n' "$LIB/The Godz/Contact High (1966)" ;;
        albumartist:Flagged) printf '%s\n' "$LIB/Flagged/Video (2001)" ;;
        'albumartist:Steve Reich') printf '%s\n' "$LIB/music_archive/Steve Reich/Drumming (1974)" ;;
        album:Contact) printf '%s\n' "$LIB/The Godz/Contact High (1966)" "$LIB/music_archive/The Godz/Contact High (1966)" ;;
        bad*) return 1 ;;
      esac
      ;;
  esac
}

# A fake soulseek_check: every album folder in $LIB/Flagged contains one failing file, video.mp4,
# unless a --skip glob matches it. Exits with CHECK_STATUS if that is set.
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
      result=$(for line in 'albumartist:"Nurse With Wound"' 'albumartist:Godz album::^Contact' "label:'A B' , label:C" "albumartist:\"Guns N' Roses\""; do
        query_words "$line" words
        printf '%s|' "$?" "${words[@]}"
        printf '\n'
      done)
      assert equal $'0|albumartist:Nurse With Wound|\n0|albumartist:Godz|album::^Contact|\n0|label:A B|,|label:C|\n0|albumartist:Guns N\' Roses|' "$result"
    ti

    it 'fails on an unmatched quote, no terms, or a field without a value'
      result=$(for line in "albumartist:Guns N' Roses" 'album:"Hopes and Fears' '' '   ' 'albumartist: "Amos & Sara"' 'album:: year:1970'; do
        query_words "$line" words
        printf '%s ' "$?"
      done)
      assert equal '1 1 1 1 1 1 ' "$result"
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

    it 'reads a ! line indented with spaces as a ! line'
      printf '%s\n' 'albumartist:"Nurse With Wound"' '   !album::(?i)live' > "$ALLOWLIST"
      main > /dev/null
      assert equal "Nurse With Wound/Chance (1979) -> $LIB/Nurse With Wound/Chance (1979)" "$(share_links)"
    ti

    it 'changes nothing and exits 1 on a line that beets would read as every album'
      result=$(for line in 'album:"Hopes and Fears' '!' 'albumartist: Godz'; do
        printf '%s\n' "$line" > "$ALLOWLIST"
        (main) > /dev/null 2>&1
        printf '%s:%s ' "$?" "$(share_links | wc -l)"
      done)
      assert equal '1:0 1:0 1:0 ' "$result"
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

    it 'shares an album of the music_archive folder under its Artist/Album name'
      printf '%s\n' 'albumartist:"Steve Reich"' > "$ALLOWLIST"
      main > /dev/null
      assert equal "Steve Reich/Drumming (1974) -> $LIB/music_archive/Steve Reich/Drumming (1974)" "$(share_links)"
    ti

    it 'changes nothing and exits 1 when two albums would get the same link name'
      printf '%s\n' 'album:Contact' > "$ALLOWLIST"
      (main) > /dev/null 2>&1
      assert equal '1 ' "$? $(share_links)"
    ti

    it 'changes nothing and exits 1 on a line or a ! line that matches no album'
      result=$(for line in 'albumartist:Nobody' '!albumartist:Nobody'; do
        printf '%s\n' 'albumartist:"Nurse With Wound"' "$line" > "$ALLOWLIST"
        (main) > /dev/null 2>&1
        printf '%s:%s ' "$?" "$(share_links | wc -l)"
      done)
      assert equal '1:0 1:0 ' "$result"
    ti

    it 'exits 2 on an unknown option or a --skip without a glob'
      result=$( (main -x) > /dev/null 2>&1; printf '%s ' $?; (main --skip) > /dev/null 2>&1; printf '%s' $?)
      assert equal '2 2' "$result"
    ti
  end_describe
end_describe

rm -rf "$TestRoot"
