RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"
TestRoot=$(mktemp -d)
export SOULSEEK_CACHE=$TestRoot/cache
LIB=$TestRoot/Music
DOWNLOADS=$TestRoot/downloads
IMPORTS=$TestRoot/imports

source "$RootDir/../../.test/shpec_utils.bash"
source "$RootDir/../.config/bash/apps/soulseek/scripts/soulseek_import.bash"

# A fake soulseek_check that fails every file named bad.flac in the last given folder
soulseek_check () {
  local line
  line=$(find "${@: -1}" -name bad.flac -printf '%p: type: neither audio nor artwork\n')
  [[ -z $line ]] || {
    printf '%s\n' "$line"
    return 1
  }
}

# A fake beets:
#   propose  fails a folder named "nomatch", proposes one missing track and no genres for a folder
#            named "partial", and proposes the genres Minimalism and Classical for a folder named
#            "one" and Minimalism for the others
#   import   (beet -c CONFIG import) appends its arguments to IMPORTS, then moves the folder's FLAC
#            files and cover.jpg (as fetchart does) into the archive unless IMPORT_SKIP is set
#   modify   appends "modify" and its arguments to IMPORTS
#   ls       prints the category, label_type, and genres values in use and the album's art path
#            for `ls -a -f`, and otherwise answers from the folders that import created
beet () {
  local output folder name status missing note genres
  case $1 in
    config) printf 'directory: %s\n' "$LIB" ;;
    propose)
      output=$3
      shift 3
      [[ $1 == --id ]] && shift 2
      for folder; do
        name=${folder##*/} status=ok missing=0 note='' genres=Minimalism
        [[ $name == nomatch ]] && status=fail
        [[ $name == partial ]] && missing=1 note='missing 1 of 3: #3 100% $5 {x}' genres=''
        [[ $name == one ]] && genres='Minimalism; Classical'
        printf '%s\n' "$folder"
        printf '%s\x1f%s\x1f\x1frel-%s\x1f2\x1f%s\x1f%s\x1fother\x1findependent\x1fmusic_archive/Artist/%s\x1f%s\n' \
          "$folder" "$status" "$name" "$missing" "$note" "$name" "$genres" >> "$output"
      done
      ;;
    -c)
      folder=${*: -1}
      printf '%s\n' "${*:4}" >> "$IMPORTS"
      [[ -n ${IMPORT_SKIP:-} ]] && return 0
      mkdir -p "$LIB/music_archive/Artist/${folder##*/}"
      mv "$folder"/*.flac "$folder/cover.jpg" "$LIB/music_archive/Artist/${folder##*/}/"
      ;;
    modify) printf 'modify %s\n' "${*:2}" >> "$IMPORTS" ;;
    ls)
      if [[ $2 == -a && $3 == -f ]]; then
        [[ $4 == '$category' ]] && printf 'noise\nother\n'
        [[ $4 == '$label_type' ]] && printf 'diy\nindependent\n'
        [[ $4 == '$genres' ]] && printf 'Classical\nMinimalism; Drone\n'
        name=${*: -2:1}
        name=${name#mb_albumid:=rel-}
        [[ $4 == '$artpath' && -f $LIB/music_archive/Artist/$name/cover.jpg ]] \
          && printf '%s\n' "$LIB/music_archive/Artist/$name/cover.jpg"
        return 0
      fi
      name=${*: -2:1}
      name=${name#mb_albumid:=rel-}
      [[ -d $LIB/music_archive/Artist/$name ]] || return 0
      if [[ $2 == -a ]]; then
        printf '%s\n' "$LIB/music_archive/Artist/$name"
      else
        printf '1\n2\n'
      fi
      ;;
  esac
}

# Writes two FLAC files, a cover, and a rip log into each given download folder name $@
make_folders () {
  local name
  for name; do
    mkdir -p "$DOWNLOADS/$name"
    printf '%s\n' "$name 1" > "$DOWNLOADS/$name/01.flac"
    printf '%s\n' "$name 2" > "$DOWNLOADS/$name/02.flac"
    printf 'jpeg\n' > "$DOWNLOADS/$name/cover.jpg"
    printf 'log\n' > "$DOWNLOADS/$name/rip.log"
  done
}

describe 'soulseek_import'
  describe 'template_literal'
    it 'escapes the characters beets templates give a meaning'
      assert equal '100$% $$5 {x$} a, b' "$(template_literal '100% $5 {x} a, b')"
    ti
  end_describe

  describe 'main'
    alias setup='rm -rf "$DOWNLOADS" "$LIB" "$SOULSEEK_CACHE" "$IMPORTS"; touch "$IMPORTS"'

    it 'imports each proposed folder into the archive with the accepted classification'
      make_folders one two
      (main "$DOWNLOADS/one" "$DOWNLOADS/two") > /dev/null
      proposed=$?
      (main --apply "$DOWNLOADS/one" "$DOWNLOADS/two" <<< $'\n\n\nnoise\ndiy\nDrone, Minimalism\n') > /dev/null 2>&1
      assert equal "0 0 --quiet --search-id rel-one --set archive=1 --set category=other --set label_type=independent --set missing=0 --set genres=Minimalism; Classical $DOWNLOADS/one
--quiet --search-id rel-two --set archive=1 --set category=noise --set label_type=diy --set missing=0 --set genres=Drone; Minimalism $DOWNLOADS/two" "$proposed $? $(< "$IMPORTS")"
    ti

    it 'moves the cover, deletes the emptied download folder, and keeps one that still has audio'
      make_folders one two
      printf 'mp3\n' > "$DOWNLOADS/two/extra.mp3"
      (main "$DOWNLOADS/one" "$DOWNLOADS/two") > /dev/null
      output=$( (main --apply "$DOWNLOADS/one" <<< $'\n\n\n') 2>&1)
      (main --apply "$DOWNLOADS/two" <<< $'\n\n\n') > /dev/null 2>&1
      result=$(for path in "$DOWNLOADS/one" "$DOWNLOADS/two/rip.log" "$LIB/music_archive/Artist/one/cover.jpg"; do
        [[ -e $path ]] && printf 'present ' || printf 'absent '
      done)
      assert equal "absent present present|  art: cover.jpg|  deleted from the download folder: rip.log" \
        "${result% }|$(grep -E '^  (art|deleted)' <<< "$output" | paste -sd '|')"
    ti

    it 'fails a folder with a failing file or without a match, and imports nothing for it'
      make_folders good checked nomatch
      printf 'x\n' > "$DOWNLOADS/checked/bad.flac"
      (main "$DOWNLOADS/good" "$DOWNLOADS/checked" "$DOWNLOADS/nomatch") > /dev/null 2>&1
      proposed=$?
      result=$(for folder in checked nomatch; do
        (main --apply "$DOWNLOADS/good" "$DOWNLOADS/$folder" <<< $'\n\n\n\n') > /dev/null 2>&1
        printf '%s ' "$?"
      done)
      assert equal "1 1 1 " "$proposed $result$(< "$IMPORTS")"
    ti

    it 'imports nothing when a file changed after the proposal'
      make_folders one two
      (main "$DOWNLOADS/one" "$DOWNLOADS/two") > /dev/null
      printf 'edited\n' >> "$DOWNLOADS/two/cover.jpg"
      (main --apply "$DOWNLOADS/one" "$DOWNLOADS/two" <<< $'\n\n\n\n') > /dev/null 2>&1
      assert equal "1 " "$? $(< "$IMPORTS")"
    ti

    it 'asks before importing an incomplete album and sets its missing fields with literal text'
      result=$(for answer in n y; do
        rm -rf "$DOWNLOADS" "$LIB" "$SOULSEEK_CACHE"
        : > "$IMPORTS"
        make_folders partial
        (main "$DOWNLOADS/partial") > /dev/null
        (main --apply "$DOWNLOADS/partial" <<< "$answer"$'\n\n\n') > /dev/null 2>&1
        printf '%s[%s]' "$?" "$(< "$IMPORTS")"
      done)
      assert equal "0[]0[--quiet --search-id rel-partial --set archive=1 --set category=other --set label_type=independent --set missing=1 --set missing_note=missing 1 of 3: #3 100\$% \$\$5 {x\$} $DOWNLOADS/partial
modify -y -a -w -M mb_albumid:=rel-partial archive:1 genres!]" "$result"
    ti

    it 'asks again for a category or label_type no album has unless the user confirms it'
      make_folders one
      (main "$DOWNLOADS/one") > /dev/null
      (main --apply "$DOWNLOADS/one" <<< $'Noise\nn\nnoise\npunk\ny\n\n') > /dev/null 2>&1
      assert equal "0 --quiet --search-id rel-one --set archive=1 --set category=noise --set label_type=punk --set missing=0 --set genres=Minimalism; Classical $DOWNLOADS/one" "$? $(< "$IMPORTS")"
    ti

    it 'splits comma-delimited genres, trims them, drops repeats, and confirms each new genre'
      make_folders one
      (main "$DOWNLOADS/one") > /dev/null
      (main --apply "$DOWNLOADS/one" <<< $'\n\n Drone ,, Kosmische,Drone \nn\nDrone, Kosmische\ny\n') > /dev/null 2>&1
      assert equal "0 --quiet --search-id rel-one --set archive=1 --set category=other --set label_type=independent --set missing=0 --set genres=Drone; Kosmische $DOWNLOADS/one" "$? $(< "$IMPORTS")"
    ti

    it 'clears the genres after the import on - and passes template characters in a category literally'
      make_folders one
      (main "$DOWNLOADS/one") > /dev/null
      (main --apply "$DOWNLOADS/one" <<< $'50% off\ny\n\n-\n') > /dev/null 2>&1
      assert equal "0 --quiet --search-id rel-one --set archive=1 --set category=50\$% off --set label_type=independent --set missing=0 $DOWNLOADS/one
modify -y -a -w -M mb_albumid:=rel-one archive:1 genres!" "$? $(< "$IMPORTS")"
    ti

    it 'exits 1 and keeps the proposal when beets does not import the album'
      make_folders one
      (main "$DOWNLOADS/one") > /dev/null
      (IMPORT_SKIP=1 main --apply "$DOWNLOADS/one" <<< $'\n\n\n') > /dev/null 2>&1
      first=$?
      (main --apply "$DOWNLOADS/one" <<< $'\n\n\n') > /dev/null 2>&1
      assert equal '1 0' "$first $?"
    ti

    it 'exits 2 on --id with several folders or with --apply, an unknown option, or no folder'
      make_folders one two
      result=$(for args in "--id x $DOWNLOADS/one $DOWNLOADS/two" "--apply --id x $DOWNLOADS/one" "-x $DOWNLOADS/one" '--apply'; do
        (main $args) > /dev/null 2>&1
        printf '%s ' "$?"
      done)
      assert equal '2 2 2 2 ' "$result"
    ti
  end_describe
end_describe

rm -rf "$TestRoot"
