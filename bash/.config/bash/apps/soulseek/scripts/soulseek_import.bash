#!/usr/bin/env bash
#desc           :Imports downloaded album folders into the beets library's music_archive folder.
#author         :Matthew Zito
#===============================================================================
# The import takes two invocations. The first checks the files with soulseek_check, matches each
# folder via the `beet propose` plugin command, prints and saves the proposals, and changes nothing.
# The second, with --apply, imports the saved proposals. It does so only if every folder passed the
# first invocation and no file in it has changed since.

readonly CACHE_DIR=${SOULSEEK_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/soulseek}
readonly PROPOSAL_DIR=$CACHE_DIR/import
readonly IMPORT_CONFIG=${SOULSEEK_IMPORT_CONFIG:-$HOME/.config/beets/soulseek-import.yaml}
readonly ARCHIVE_DIR=music_archive
# `beet propose` separates the fields of each record with U+001F (the ASCII unit separator)
readonly SEPARATOR=$'\x1f'
# beets formats and parses a multi-value field such as genres with this delimiter
readonly GENRE_DELIMITER='; '
readonly WARNING_SUFFIX=' (warning)'
# soulseek_check's line for a file that is neither audio nor artwork; such a file does not fail a
# folder, because beets imports only the audio and the image, and --apply asks before deleting it
readonly TYPE_FAILURE=': type: neither audio nor artwork'
# A record of the current RECORD_FIELDS of `beet propose` contains 9 separators (10 fields)
readonly RECORD_SEPARATORS=9
# The audio extensions of beet propose's audio_items, space-delimited with a space at each end
readonly AUDIO_EXTENSIONS=' aac aif aiff alac ape flac m4a m4p mp3 mp4 mpc ogg opus wav wma wv '

die () {
  printf 'soulseek_import: %s\n' "$@" >&2
  exit 1
}

usage () {
  cat << EOF
Usage: soulseek_import [-i RELEASE_ID] [-s GLOB]... FOLDER...
       soulseek_import --apply [-s GLOB]... FOLDER...

Imports album folders, one album per folder, into $ARCHIVE_DIR/ of the beets library.

Without --apply, executes soulseek_check on every file and matches each folder against
MusicBrainz and Discogs, then prints for each folder the release, the library folder and file
names it would get, the missing tracks, and the proposed category and genres. It changes nothing
in the library or the folders. A folder fails when a file fails a check, when no release matches
well enough, when a file matches no track of the release, or when the release, or an album with
the same album artist and title, is already in the library. A file that is neither audio nor
artwork (soulseek_check's "type" line) does not fail its folder. Exits 0 when every folder passes
and 1 otherwise.

With --apply, imports the folders of the last run. It stops before importing anything unless
every folder passed that run and no file changed since. It asks whether to import each
incomplete album, then asks for each album's category and genres, offering the proposed values.
genres takes a comma-delimited list, or - for none. Each value must be one that an album in the
library already has, or a new value that you confirm. beets writes the tags, moves the audio
files and the album's image (as cover.<ext>, not embedded) to the library, and sets archive=1,
category, genres, missing, and missing_note. After the imports, it lists the files left in each
download folder and asks whether to delete the folder; an empty folder is deleted without asking,
and a folder that still contains an audio file is kept.

  -i, --id ID      match the folder only against this MusicBrainz or Discogs release ID, at any
                   similarity; takes exactly one FOLDER
  -s, --skip GLOB  do not check files whose path matches GLOB (see soulseek_check -h); repeatable
      --apply      import the folders as proposed
  -h, --help       show this help
EOF
}

# Prints the path of the saved proposal for the given folder $1. The file name is the SHA-256 of
# the folder's path, which is safe as a file name whatever characters the path contains.
proposal_file () {
  local sum
  sum=$(printf '%s' "$1" | sha256sum) || die 'sha256sum failed'
  # sha256sum prints "<hash>  -"; `%% *` removes everything from the first space onward
  printf '%s/%s\n' "$PROPOSAL_DIR" "${sum%% *}"
}

# Prints the NUL-delimited SHA-256 and path of every file in the given folder $1, sorted by path.
# Two equal outputs therefore prove that no file was added, removed, or changed.
manifest () {
  find "$1" -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum --zero --
}

# Executes soulseek_check with the given arguments $@ and prints its output. Fills the associative
# array FAILED, keyed by folder, with each folder of FOLDERS in which a file failed a check.
# Neither a warning line nor a TYPE_FAILURE line fails its folder.
check_folders () {
  local output status=0 line folder
  # `|| status=$?` records soulseek_check's exit status lest `set -e` exit on status 1
  output=$(soulseek_check "$@") || status=$?
  ((status <= 1)) || die "soulseek_check exited with status $status"
  [[ -z $output ]] || printf '%s\n' "$output"
  # Each line reads "path: check: detail"; a line belongs to a folder if its path begins with it
  while IFS= read -r line; do
    [[ -n $line && $line != *"$WARNING_SUFFIX" && $line != *"$TYPE_FAILURE" ]] || continue
    for folder in "${FOLDERS[@]}"; do
      [[ $line == "$folder/"* ]] && FAILED[$folder]=1
    done
  done <<< "$output"
}

# Splits the given record line $1 of `beet propose` into the associative array whose name is the
# given $2, keyed by the record's field names.
read_record () {
  # -n makes record_ a reference to the caller's array, so assignments to it fill that array
  local -n record_=$2
  local -a values
  # IFS set to a non-whitespace separator keeps empty fields, yet read drops trailing empty
  # fields; the `:-` defaults therefore supply them.
  IFS=$SEPARATOR read -r -a values <<< "$1"
  # shellcheck disable=SC2034 # record_ refers to the caller's array
  record_=([folder]=${values[0]:-} [status]=${values[1]:-} [reason]=${values[2]:-}
    [release_id]=${values[3]:-} [tracks]=${values[4]:-} [missing]=${values[5]:-0}
    [missing_note]=${values[6]:-} [category]=${values[7]:-} [destination]=${values[8]:-}
    [genres]=${values[9]:-})
}

# Saves the given record line $1 and the manifest of its folder if the folder passed, and removes
# any saved proposal of the folder otherwise. Prints the folder if it failed.
save_proposal () {
  local -A record
  local file
  read_record "$1" record
  file=$(proposal_file "${record[folder]}")
  if [[ ${record[status]} != ok || -n ${FAILED[${record[folder]}]:-} ]]; then
    rm -f -- "$file" "$file.files"
    printf '%s\n' "${record[folder]}"
    return 0
  fi
  printf '%s\n' "$1" > "$file" || die "saving the proposal for ${record[folder]} failed"
  manifest "${record[folder]}" > "$file.files" || die "hashing ${record[folder]} failed"
}

# Proposes an import of every folder of FOLDERS, matched only against the given release ID $1 if
# it is not empty; the remaining arguments $@ are passed to soulseek_check. Fails if any folder
# failed.
propose () {
  local release_id=$1 records line failed
  local -a check_args=("${@:2}") propose_args=() failures=()
  local -A FAILED=()

  # 1. Check every file; check_folders fills FAILED.
  check_folders "${check_args[@]}" -- "${FOLDERS[@]}"

  # 2. Match every folder. `beet propose` prints the proposals and appends one record per folder to
  # the records file.
  [[ -z $release_id ]] || propose_args=(--id "$release_id")
  mkdir -p -- "$PROPOSAL_DIR" || die "creating $PROPOSAL_DIR failed"
  records=$(mktemp) || die 'mktemp failed'
  # shellcheck disable=SC2064 # $records is expanded now, as intended
  trap "rm -f -- '$records'" EXIT
  beet propose -o "$records" "${propose_args[@]}" "${FOLDERS[@]}" || die 'beet propose failed'

  # 3. Save the proposal of each folder that passed both steps, and collect the others.
  while IFS= read -r line; do
    failed=$(save_proposal "$line") || exit 1
    [[ -z $failed ]] || failures+=("$failed")
  done < "$records"

  # 4. Pass only if no folder failed.
  if ((${#failures[@]})); then
    printf 'soulseek_import: %s of %s folders failed; fix or remove them, then run soulseek_import again:\n' \
      "${#failures[@]}" "${#FOLDERS[@]}" >&2
    printf '  %s\n' "${failures[@]}" >&2
    return 1
  fi
  printf 'soulseek_import: every folder passed; import them with soulseek_import --apply and the same folders\n'
}

# Prints the saved record line of the given folder $1. Fails unless the folder passed its last
# proposal, that proposal has the current record fields, and the folder's manifest still equals the
# one saved with it.
saved_record () {
  local file line separators
  file=$(proposal_file "$1")
  [[ -f $file ]] || die "no passing proposal for $1; run soulseek_import on it first"
  line=$(< "$file")
  # `//[!$SEPARATOR]/` removes every character but the separators, which leaves their count
  separators=${line//[!$SEPARATOR]/}
  ((${#separators} == RECORD_SEPARATORS)) \
    || die "the proposal for $1 predates this soulseek_import; run soulseek_import on it again"
  # <(...) presents the current manifest to cmp as a file
  cmp -s -- "$file.files" <(manifest "$1") || die "$1 changed since its proposal; run soulseek_import on it again"
  printf '%s\n' "$line"
}

# Prints the newline-delimited distinct values of the given album field $1 in the library, sans
# albums without the field.
library_values () {
  # `$1::.` is a beets regular-expression query that matches every non-empty value; `\$$1` is
  # the literal beets template $<field>
  beet ls -a -f "\$$1" "$1::." | LC_ALL=C sort -u
}

# Prints the newline-delimited distinct genres of the library's albums.
library_genres () {
  # beet ls prints an album's genres joined by GENRE_DELIMITER; awk prints each on its own line
  # shellcheck disable=SC2016 # $genres is a beets template field
  beet ls -a -f '$genres' 'genres::.' \
    | awk -F "$GENRE_DELIMITER" '{ for (i = 1; i <= NF; i++) print $i }' | LC_ALL=C sort -u
}

# Asks the yes-or-no question $1, with no as the default, and succeeds on yes.
ask_yes () {
  local answer
  read -r -p "$1 [y/N]: " answer || die 'no answer'
  [[ $answer == [yY] || $answer == [yY][eE][sS] ]]
}

# Asks for the given album field $1 until the answer is one of the given newline-delimited values
# $3 or a new value the user confirms, and prints the answer. An empty answer selects the given
# proposed value $2.
ask_value () {
  local field=$1 proposal=$2 in_use=$3 answer shown
  while true; do
    # read -p prints its prompt to stderr, so the prompt is not part of the printed answer
    read -r -p "  $field [${proposal:-none}]: " answer || die 'no answer'
    answer=${answer:-$proposal}
    [[ -n $answer ]] || continue
    # Wrapping the list and the answer in newlines makes the pattern match whole lines only
    [[ $'\n'$in_use$'\n' == *$'\n'"$answer"$'\n'* ]] && break
    # `//$'\n'/, ` replaces every newline with a comma and a space
    shown=${in_use//$'\n'/, }
    printf '  no album has %s %s; in use: %s\n' "$field" "$answer" "${shown:-none}" >&2
    ask_yes "  use $answer anyway?" && break
  done
  printf '%s\n' "$answer"
}

# Asks for the album's genres until every comma-delimited genre of the answer is one of the given
# newline-delimited genres $2 or a new genre the user confirms. Prints the genres joined by
# GENRE_DELIMITER. An empty answer selects the given proposed genres $1 (joined by
# GENRE_DELIMITER), and - selects no genre.
ask_genres () {
  local proposal=$1 in_use=$2 answer genre confirmed shown
  local -a parts genres
  local -A seen
  # The proposal is shown as the user types it: comma-delimited
  shown=${proposal//"$GENRE_DELIMITER"/, }
  while true; do
    read -r -p "  genres [${shown:-none}]: " answer || die 'no answer'
    [[ -n $answer ]] || answer=${proposal//"$GENRE_DELIMITER"/,}
    [[ $answer == - ]] && answer=''
    # 1. Split the answer at commas, trim the spaces around each genre, and drop empty and
    # repeated genres.
    IFS=, read -r -a parts <<< "$answer"
    genres=() seen=()
    for genre in "${parts[@]}"; do
      # `%%[![:space:]]*` is the leading whitespace and `##*[![:space:]]` the trailing whitespace
      genre=${genre#"${genre%%[![:space:]]*}"}
      genre=${genre%"${genre##*[![:space:]]}"}
      [[ -n $genre && -z ${seen[$genre]:-} ]] || continue
      seen[$genre]=1
      genres+=("$genre")
    done
    # 2. Confirm each genre no album has yet; a refusal asks the question again.
    confirmed=1
    for genre in "${genres[@]}"; do
      [[ $'\n'$in_use$'\n' == *$'\n'"$genre"$'\n'* ]] && continue
      printf '  no album has the genre %s\n' "$genre" >&2
      ask_yes "  use $genre anyway?" || {
        confirmed=''
        break
      }
    done
    [[ -n $confirmed ]] && break
  done
  # 3. Join the genres with GENRE_DELIMITER, which beets parses back into a list.
  local IFS=$'\n'
  answer="${genres[*]}"
  printf '%s\n' "${answer//$'\n'/$GENRE_DELIMITER}"
}

# Escapes the beets template characters in the given value $1. import --set evaluates its values
# as templates (per ImportTask.set_fields), in which $ % and } carry a meaning unless a $ precedes
# them.
# See: https://beets.readthedocs.io/en/stable/reference/pathformat.html
template_literal () {
  # Each `${value//X/Y}` replaces every X with Y; $ is escaped first, lest the escapes that
  # the later replacements add are themselves escaped
  local value=${1//\$/\$\$}
  value=${value//%/\$%}
  printf '%s\n' "${value//\}/\$\}}"
}

# Imports the folder of the record whose name is the given $1, with the given category $2 and
# genres $3 (joined by GENRE_DELIMITER), into the given library folder $4. Prints the album's new
# folder; beets prints its own output to stderr.
import_album () {
  local -n album_=$1
  local library=$4 id=${album_[release_id]} imported count
  local -a fields=(--set archive=1 --set "category=$(template_literal "$2")"
  --set "missing=${album_[missing]}")
  # import --set rejects an empty value, so no genres are cleared in step 3 instead
  [[ -z $3 ]] || fields+=(--set "genres=$(template_literal "$3")")
  [[ -z ${album_[missing_note]} ]] \
    || fields+=(--set "missing_note=$(template_literal "${album_[missing_note]}")")

  # 1. Import with the proposed release. The overlay IMPORT_CONFIG accepts said release at any
  # distance.
  beet -c "$IMPORT_CONFIG" import --quiet --search-id "$id" "${fields[@]}" "${album_[folder]}" >&2 \
    || die "beet import failed for ${album_[folder]}"

  # 2. Confirm the import. A quiet beet import that skips an album exits 0, so the library itself
  # must show the album in the archive with the proposed number of tracks.
  imported=$(beet ls -a -p "mb_albumid:=$id" archive:1) || die 'beet ls failed'
  # shellcheck disable=SC2016 # $id is a beets template field
  count=$(beet ls -f '$id' "mb_albumid:=$id" archive:1 | wc -l) || die 'beet ls failed'
  [[ $imported == "$library/$ARCHIVE_DIR/"* && $count == "${album_[tracks]}" ]] \
    || die "beets did not import ${album_[folder]} as proposed: ${imported:-not imported}, $count of ${album_[tracks]} tracks"

  # 3. Clear the genres the files' tags brought along if the user chose none. `genres!` sets the
  # field to an empty list, -w writes that to the tags, -M moves no file, and -y skips the
  # confirmation.
  if [[ -z $3 ]]; then
    beet modify -y -a -w -M "mb_albumid:=$id" archive:1 'genres!' >&2 \
      || die "clearing the genres of $imported failed"
  fi
  printf '%s\n' "$imported"
}

# Prints the image beets moved into the album with the given release ID $1, or nothing if the
# album has none.
album_art () {
  local art
  # shellcheck disable=SC2016 # $artpath is a beets template field
  art=$(beet ls -a -f '$artpath' "mb_albumid:=$1" archive:1) || return 1
  # `##*/` leaves the file name
  printf '%s\n' "${art##*/}"
}

# Deletes the given download folder $1 after its import. Deletes an empty folder without asking,
# keeps a folder that still contains an audio file, and otherwise lists the remaining files and
# asks first. Refuses a folder in the given library folder $2.
remove_download () {
  local folder=$1 library=$2 file name extension
  local -a files=()
  [[ -d $folder ]] || return 0
  [[ $folder != "$library" && $folder != "$library"/* ]] || die "refusing to delete $folder in the library"
  # 1. Collect the remaining files, and keep the folder if beets left an audio file in it.
  while IFS= read -r -d '' file; do
    # `##*/` leaves the file name and `##*.` its extension; `,,` lowercases it
    name=${file##*/}
    extension=''
    [[ $name == *.* ]] && extension=${name##*.}
    if [[ -n $extension && $AUDIO_EXTENSIONS == *" ${extension,,} "* ]]; then
      printf 'soulseek_import: kept %s, which still contains %s\n' "$folder" "${file#"$folder"/}" >&2
      return 0
    fi
    files+=("${file#"$folder"/}")
  done < <(find "$folder" -type f -print0)

  # 2. Ask before deleting files; an empty folder needs no question.
  if ((${#files[@]})); then
    printf '\n%s still contains:\n' "$folder"
    printf '  %s\n' "${files[@]}"
    if ! ask_yes '  delete the folder and these files?'; then
      printf 'soulseek_import: kept %s\n' "$folder"
      return 0
    fi
  fi
  rm -r -- "$folder" || die "deleting $folder failed"
  printf 'soulseek_import: deleted %s\n' "$folder"
}

# Imports every folder of FOLDERS as proposed; the given arguments $@ are passed to soulseek_check.
apply () {
  local folder line library imported art categories_in_use genres_in_use i
  local -a check_args=("$@") records=() categories=() genres=() imported_folders=()
  local -A record FAILED=()

  # 1. Load every saved proposal, which also confirms that no file changed since.
  for folder in "${FOLDERS[@]}"; do
    line=$(saved_record "$folder") || exit 1
    records+=("$line")
  done

  # 2. Check every file again. The soulseek_check cache answers for unchanged files, yet newer
  # ClamAV signatures cause a new scan.
  check_folders "${check_args[@]}" -- "${FOLDERS[@]}"
  ((${#FAILED[@]} == 0)) || die 'files failed soulseek_check since the proposal; run soulseek_import again'
  library=$(beet config | sed -n 's/^directory: //p') || die 'beet config failed'
  # beet config prints the directory as written in the config; this expands a leading ~
  library=${library/#\~/$HOME}

  # 3. Ask every question prior to the first import. An empty category marks a skipped album.
  categories_in_use=$(library_values category) || die 'beet ls failed'
  genres_in_use=$(library_genres) || die 'beet ls failed'
  for i in "${!records[@]}"; do
    read_record "${records[i]}" record
    printf '\n%s\n  -> %s\n' "${record[folder]}" "${record[destination]}"
    if ((record[missing] > 0)) && ! ask_yes "  ${record[missing_note]}; import it incomplete?"; then
      categories[i]=''
      continue
    fi
    categories[i]=$(ask_value category "${record[category]}" "$categories_in_use")
    genres[i]=$(ask_genres "${record[genres]}" "$genres_in_use")
  done

  # 4. Import each album that was not skipped. A failed import stops the invocation and keeps the
  # proposals and folders of the albums not yet imported.
  for i in "${!records[@]}"; do
    read_record "${records[i]}" record
    if [[ -z ${categories[i]} ]]; then
      printf 'soulseek_import: skipped %s\n' "${record[folder]}"
      continue
    fi
    imported=$(import_album record "${categories[i]}" "${genres[i]}" "$library") || exit 1
    imported_folders+=("${record[folder]}")
    # `{,.files}` expands to the proposal file and its manifest
    rm -f -- "$(proposal_file "${record[folder]}")"{,.files}
    printf 'soulseek_import: imported %s\n' "$imported"
    art=$(album_art "${record[release_id]}") || die 'beet ls failed'
    printf '  art: %s\n' "${art:-none}"
  done

  # 5. Offer to delete each imported album's download folder, after every import so that the
  # imports need no attention.
  for folder in "${imported_folders[@]}"; do
    remove_download "$folder" "$library"
  done
  # beets rewrote every imported file with its tags, which changed each file's SHA-256. The files are
  # not checked again here: soulseek_share checks an album the first time it shares it.
}

# Lowers the CPU and I/O priority of this process and so of every command it executes, which
# leaves the desktop responsive while the checks occupy the remaining cores.
lower_priority () {
  renice -n 19 -p $$ > /dev/null 2>&1 || true
  # Class 3 (idle) receives disk time only when no other process requests it
  ionice -c 3 -p $$ > /dev/null 2>&1 || true
}

main () {
  local applying='' release_id='' resolved
  local -a check_args=()
  while (($#)); do
    case $1 in
      --apply)
        applying=1
        shift
        ;;
      -i | --id | -s | --skip)
        (($# >= 2)) || {
          usage >&2
          return 2
        }
        if [[ $1 == -i || $1 == --id ]]; then release_id=$2; else check_args+=(--skip "$2"); fi
        shift 2
        ;;
      -h | --help)
        usage
        return 0
        ;;
      -*)
        usage >&2
        return 2
        ;;
      *) break ;;
    esac
  done
  (($#)) || {
    usage >&2
    return 2
  }
  # A release ID names one release, so it applies to exactly one folder of a proposal
  [[ -z $release_id || ($# -eq 1 && -z $applying) ]] || {
    usage >&2
    return 2
  }

  local folder
  for folder; do
    [[ -d $folder ]] || die "not a folder: $folder"
  done
  # realpath -s makes every path absolute sans resolving symlinks, so that proposals saved from
  # one working directory are found from another
  resolved=$(realpath -s -- "$@") || die 'realpath failed'
  local -a FOLDERS
  mapfile -t FOLDERS <<< "$resolved"
  if [[ -n $applying ]]; then
    apply "${check_args[@]}"
  else
    propose "$release_id" "${check_args[@]}"
  fi
}

# stop here if being sourced
return 2> /dev/null

set -euo pipefail

lower_priority
main "$@"
