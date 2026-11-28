#!/usr/bin/env bash
#desc           :Checks downloaded music files for malware, damage, and lossy transcodes.
#author         :Matthew Zito
#===============================================================================
# Executes the batch checks on music files: a ClamAV scan, a file type allowlist, the real type of
# each audio file, a full decode, `flac -t` on FLAC files, and a test for lossless files decoded
# from a lossy encoding. Prints one line per failed check or warning and changes no file. Results
# are cached by file content in CACHE_FILE.

# Extension lists are space-delimited with a space at each end, so `== *" $extension "*` matches
# whole words only
readonly AUDIO_EXTENSIONS=' flac mp3 m4a ogg opus wav aiff '
readonly ARTWORK_EXTENSIONS=' jpg jpeg png cue log txt '
readonly LOSSLESS_EXTENSIONS=' flac wav aiff '
# Lowercase regular expression for the descriptions `file` gives each audio format
readonly AUDIO_TYPES='audio|flac|mpeg|ogg|wave|iso media'
readonly INCOMPLETE_DIR=${SOULSEEK_INCOMPLETE:-$HOME/Downloads/soulseek/incomplete}
readonly SIGNATURE_MAX_AGE_DAYS=3
# A few damaged frames in a file that otherwise decodes are inaudible (an MP3 frame lasts about
# 26 ms); up to MAX_DAMAGED_FRAMES of them are therefore a warning.
readonly MAX_DAMAGED_FRAMES=50
readonly WARNING_SUFFIX=' (warning)'
# One job per physical core (lscpu prints one CORE,SOCKET line per logical CPU, and the two
# hyperthreads of a core share a pair). A second job on a core's other hyperthread adds little
# throughput and slows every other process on that core.
JOBS=$(lscpu --parse=CORE,SOCKET 2> /dev/null | grep -v '^#' | sort -u | wc -l)
((JOBS > 0)) || JOBS=$(nproc)
readonly JOBS

# Each row of CACHE_FILE reads "sha256<TAB>version<TAB>result" and records one result of the
# checks that version names, on the file with that SHA-256. An empty result records a pass.
# The version is either "malware:" followed by the ClamAV version line, whose signature number
# changes with every signature update, or "files:" followed by a hash of this script and of the
# versions of ffmpeg, flac, and file. A result is therefore reused only for identical content
# checked by identical code.
readonly CACHE_FILE=${SOULSEEK_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/soulseek}/check.tsv

# A lossy encoder's lowpass filter leaves a drop of CUTOFF_DROP_DB or more between two adjacent
# 1 kHz bands. A quiet upper range (as in drone music) is no such drop, so the band below the drop
# must be louder than AUDIBLE_DB. The bands stop at 20 kHz because a genuine CD's anti-alias
# filter also drops steeply above it. Files below MIN_SAMPLE_RATE are not tested, because their
# Nyquist frequency (half the sample rate, the highest frequency a file can contain) falls inside
# the bands.
readonly BAND_EDGES=(13000 14000 15000 16000 17000 18000 19000 20000)
readonly CUTOFF_DROP_DB=30
readonly AUDIBLE_DB=-90
readonly MIN_SAMPLE_RATE=44100

# Globs from --skip, matched against each file's absolute path
SKIP=()

die () {
  printf 'soulseek_check: %s\n' "$@" >&2
  exit 2
}

usage () {
  cat << EOF
Usage: soulseek_check [-s GLOB]... PATH...

Checks every file in each PATH (files or directories, followed through symlinks) and prints
one "path: check: detail" line per failure, and the same line ending in "$WARNING_SUFFIX" per
warning. Exits 0 when no file fails, including when there are warnings, and 1 when any fails.

  -s, --skip GLOB  do not check files whose absolute path matches GLOB, a bash pattern in
                   which * also matches /; repeat for more globs
  -h, --help       show this help

Checks:
  malware    ClamAV flags the file (signatures older than $SIGNATURE_MAX_AGE_DAYS days are reported)
  type       the extension is neither audio (${AUDIO_EXTENSIONS# }) nor artwork or notes (${ARTWORK_EXTENSIONS# })
  content    an audio file's content is not audio, whatever its extension says
  decode     ffmpeg cannot decode the file, or finds more than $MAX_DAMAGED_FRAMES damaged frames in it;
             1 to $MAX_DAMAGED_FRAMES damaged frames are a warning
  flac       flac -t reports an error in a FLAC file
  transcode  a FLAC, WAV, or AIFF file has a lossy encoder's cutoff below 20 kHz; check it in Spek.
             Cutoffs of 320 kbit/s and V0 MP3s lie above 20 kHz and pass.

Files in $INCOMPLETE_DIR are not checked.

Results are cached in $CACHE_FILE by each file's SHA-256, so a file is checked again only when
its content, this script, or the version of ClamAV's signatures, ffmpeg, flac, or file changes.
EOF
}

# Succeeds if the given path $1 matches a --skip glob.
skipped () {
  local glob
  for glob in "${SKIP[@]}"; do
    # An unquoted right-hand side makes == a glob match
    # shellcheck disable=SC2053
    [[ $1 == $glob ]] && return 0
  done
  return 1
}

# Prints the NUL-delimited files in the given paths $@, sans skipped files and partial downloads.
list_files () {
  local file
  # -L follows symlinks; `-path X -prune -o` excludes the folder X and everything in it
  while IFS= read -r -d '' file; do
    skipped "$file" || printf '%s\0' "$file"
  done < <(find -L "$@" -path "$INCOMPLETE_DIR" -prune -o -type f -print0)
}

# Reports on stderr if the ClamAV signatures of the given version line $1 are older than
# SIGNATURE_MAX_AGE_DAYS.
warn_old_signatures () {
  local built age
  # The version line reads "ClamAV 1.5.4/28194/Tue Nov 24 22:26:59 2026"; `##*/` removes all up
  # to the last slash, which leaves the signature date
  built=$(date -d "${1##*/}" +%s 2> /dev/null) || return 0
  age=$((($(date +%s) - built) / 86400))
  ((age <= SIGNATURE_MAX_AGE_DAYS)) \
    || printf 'soulseek_check: the ClamAV signatures are %s days old; run sudo freshclam\n' "$age" >&2
}

# Prints the cache version of the checks other than the malware check: "files:" and the SHA-256 of
# this script followed by the first version lines of ffmpeg, flac, and file.
files_version () {
  local ffmpeg_version flac_version file_version sum
  ffmpeg_version=$(ffmpeg -version) || die 'ffmpeg -version failed'
  flac_version=$(flac --version) || die 'flac --version failed'
  file_version=$(file --version) || die 'file --version failed'
  # `%%$'\n'*` removes all from the first newline onward, which leaves the first line; `cat X -`
  # writes this script X followed by its stdin (the version lines) into sha256sum
  sum=$(printf '%s\n' "${ffmpeg_version%%$'\n'*}" "$flac_version" "${file_version%%$'\n'*}" \
    | cat -- "${BASH_SOURCE[0]}" - | sha256sum) || die 'hashing the checks failed'
  printf 'files:%s\n' "${sum%% *}"
}

# Fills the associative array HASHES, keyed by path, with the SHA-256 of each file in the given
# NUL-delimited list file $1.
load_hashes () {
  local record
  # sha256sum --zero prints NUL-terminated "<hash>  <path>" records sans escaping odd characters;
  # `#*  ` leaves the path and `%%  *` the hash
  while IFS= read -r -d '' record; do
    HASHES[${record#*  }]=${record%%  *}
  done < <(xargs -0 -r sha256sum --zero -- < "$1")
  # $! is the process substitution's process ID; waiting for it yields sha256sum's exit status
  wait $! || die 'sha256sum failed'
}

# Fills the associative array CACHED with the cached results of the given versions $1 and $2,
# keyed "sha256<TAB>version", as newline-delimited result lines. Rewrites the cache sans the rows
# of other versions, which no invocation can reuse.
load_cache () {
  local hash version result kept
  [[ -f $CACHE_FILE ]] || return 0
  kept=$(mktemp "$CACHE_FILE.XXXXXX") || die 'mktemp failed'
  while IFS=$'\t' read -r hash version result; do
    [[ $version == "$1" || $version == "$2" ]] || continue
    # `+=` creates the key even for an empty result (a pass); `${result:+X}` adds X only for a
    # non-empty result, so a pass adds no line
    CACHED[$hash$'\t'$version]+=${result:+$result$'\n'}
    printf '%s\t%s\t%s\n' "$hash" "$version" "$result"
  done < "$CACHE_FILE" > "$kept"
  # mv replaces the cache in one rename, so a concurrent invocation reads either file whole
  mv -- "$kept" "$CACHE_FILE" || die 'rewriting the cache failed'
}

# Prints each result line cached in CACHED for the given file $1 and cache key $2, as
# "path: result".
print_cached () {
  local line
  while IFS= read -r line; do
    [[ -z $line ]] || printf '%s: %s\n' "$1" "$line"
  done <<< "${CACHED[$2]}"
}

# Appends a cache row for each given newline-delimited result $3 (none for a pass) of the given
# version $2 for the given file $1. Appends nothing if the file's SHA-256 no longer equals the one
# in HASHES. This ensures a file that changed during its checks leaves no row.
record () {
  local hash=${HASHES[$1]} sum line
  sum=$(sha256sum < "$1") || return 0
  [[ ${sum%% *} == "$hash" ]] || return 0
  # `>>` opens the cache with O_APPEND, and each printf issues one write. Per write(2), "the
  # adjustment of the file offset and the write operation are performed as an atomic step"; the
  # rows of parallel jobs therefore do not interleave.
  while IFS= read -r line; do
    printf '%s\t%s\t%s\n' "$hash" "$2" "${line//$'\t'/ }"
  done <<< "$3" >> "$CACHE_FILE"
}

# Fills the associative array FOUND, keyed by path, with the signature ClamAV finds in each file
# of the given newline-delimited list file $1.
scan_malware () {
  local output status=0 line
  # clamscan exits 1 if it finds malware and 2 or above on an error
  output=$(clamscan --infected --no-summary --file-list="$1") || status=$?
  ((status <= 1)) || die "clamscan exited with status $status"
  # Each finding reads "path: signature FOUND"
  while IFS= read -r line; do
    [[ $line == *' FOUND' ]] || continue
    line=${line% FOUND}
    FOUND[${line%: *}]=${line##*: }
  done <<< "$output"
}

# Prints a malware line for each file in the given NUL-delimited list file $1 that ClamAV flags.
# Only files sans a cached result of the given version $2 are scanned, via the given list file $3.
check_malware () {
  local file key result
  local -a scan=()
  local -A FOUND=()
  # 1. Print the cached results, and collect the files to scan.
  while IFS= read -r -d '' file; do
    key=${HASHES[$file]}$'\t'$2
    # -v tests whether the key exists, including one whose value is empty (a pass)
    if [[ -v CACHED[$key] ]]; then print_cached "$file" "$key"; else scan+=("$file"); fi
  done < "$1"
  ((${#scan[@]})) || return 0

  # 2. Scan the remaining files in one clamscan invocation, which loads the signatures only once.
  printf '%s\n' "${scan[@]}" > "$3"
  scan_malware "$3"

  # 3. Print and cache each new result.
  for file in "${scan[@]}"; do
    result=${FOUND[$file]:+malware: ${FOUND[$file]}}
    [[ -z $result ]] || printf '%s: %s\n' "$file" "$result"
    record "$file" "$2" "$result"
  done
}

# Prints the ffmpeg filter graph that measures the RMS level of each band between BAND_EDGES.
# The graph mixes the audio down to mono, splits it into one copy per band, removes all but the
# band from each copy, and measures each copy with an astats filter named after its lower edge.
band_graph () {
  local i graph outputs='' count=$((${#BAND_EDGES[@]} - 1))
  graph="[0:a]aformat=sample_fmts=fltp:channel_layouts=mono,asplit=$count"
  for ((i = 0; i < count; i++)); do
    graph+="[s$i]"
  done
  for ((i = 0; i < count; i++)); do
    # The equalizer passes the band at 0 dB and attenuates all other frequencies by 200 dB
    graph+=";[s$i]firequalizer=gain='if(between(f,${BAND_EDGES[i]},${BAND_EDGES[i + 1]}),0,-200)'"
    graph+=":delay=0.05:accuracy=1:wfunc=nuttall"
    graph+=",astats@b${BAND_EDGES[i]}=measure_overall=RMS_level:measure_perchannel=none[o$i]"
    outputs+="[o$i]"
  done
  # ffmpeg requires one output; amix joins the measured copies into it
  printf '%s;%samix=inputs=%s[out]' "$graph" "$outputs" "$count"
}

# Prints "rate HZ" for each audio stream of the given file $1, then "EDGE LEVEL" for each band,
# where LEVEL is the band's RMS level in dBFS over the whole file. Both come from ffmpeg's log.
band_levels () {
  # One thread per ffmpeg: check_each_file already executes JOBS of them in parallel
  ffmpeg -nostdin -hide_banner -nostats -threads 1 -filter_complex_threads 1 -v info -i "$1" \
    -filter_complex "$(band_graph)" \
    -map '[out]' -f null - 2>&1 \
    | sed -n -E \
      -e 's/^ *Stream #0:[0-9]+[^:]*: Audio: [^,]*, ([0-9]+) Hz.*/rate \1/p' \
      -e 's/^\[astats@b([0-9]+) @ [^]]*\] RMS level dB: (.*)$/\1 \2/p'
}

# Reads band_levels output from stdin and prints "N dB drop at K kHz" for the steepest drop
# between adjacent bands, if said drop is a lossy cutoff per the thresholds above. Prints nothing
# otherwise.
cutoff () {
  # sort -n orders the bands upward from 13 kHz, and "rate" lines sort after them
  sort -n | awk -v drop_db="$CUTOFF_DROP_DB" -v audible_db="$AUDIBLE_DB" -v min_rate="$MIN_SAMPLE_RATE" '
    $1 == "rate" { if (rate == "") rate = $2; next }
    {
      # astats prints "-inf" for a silent band; it is read as -200 dB
      level = ($2 ~ /^-?[0-9]+(\.[0-9]+)?$/) ? $2 + 0 : -200
      # bands++ is 0 for the first band, which has no band below it
      if (bands++ && previous > audible_db && previous - level > drop) {
        drop = previous - level
        edge = $1
      }
      previous = level
    }
    END { if (rate + 0 >= min_rate && drop >= drop_db) printf "%d dB drop at %d kHz\n", drop, edge / 1000 }
  '
}

# Prints a decode line for the given file $1 if ffmpeg cannot decode it or finds damaged frames in
# it. ffmpeg prints "Error submitting packet to decoder" once per damaged frame; the repeat flag
# prevents it from folding identical lines into "Last message repeated" lines. Other error output
# counts one frame per line.
check_decode () {
  local errors damaged unit=frames suffix=$WARNING_SUFFIX
  # `2>&1 > /dev/null` sends stderr into the substitution and discards stdout
  if ! errors=$(ffmpeg -nostdin -threads 1 -v repeat+error -i "$1" -f null - 2>&1 > /dev/null); then
    printf '%s: decode: ffmpeg cannot decode the file\n' "$1"
    return 0
  fi
  [[ -n $errors ]] || return 0
  damaged=$(grep -c 'Error submitting packet to decoder' <<< "$errors")
  ((damaged)) || damaged=$(wc -l <<< "$errors")
  ((damaged == 1)) && unit=frame
  ((damaged > MAX_DAMAGED_FRAMES)) && suffix=''
  printf '%s: decode: %s damaged %s%s\n' "$1" "$damaged" "$unit" "$suffix"
  return 0
}

# Prints a line for each audio check that the given file $1, of the given lowercase extension $2,
# fails.
check_audio () {
  local file=$1 extension=$2 type drop
  type=$(file -b -- "$file")
  # `${type,,}` is the description in lowercase
  if ! [[ ${type,,} =~ $AUDIO_TYPES ]]; then
    printf '%s: content: %s\n' "$file" "$type"
    return 0
  fi
  check_decode "$file"
  if [[ $extension == flac ]] && ! flac -t -s -- "$file" > /dev/null 2>&1; then
    printf '%s: flac: flac -t reports an error\n' "$file"
  fi
  if [[ $LOSSLESS_EXTENSIONS == *" $extension "* ]]; then
    drop=$(band_levels "$file" | cutoff)
    [[ -z $drop ]] || printf '%s: transcode: %s\n' "$file" "$drop"
  fi
  return 0
}

# Prints a line for each check sans the malware check that the given file $1 fails.
check_file () {
  # `##*/` leaves the file name and `##*.` its extension
  local file=$1 name=${1##*/} extension=''
  [[ $name == *.* ]] && extension=${name##*.}
  extension=${extension,,}
  if [[ -n $extension && $AUDIO_EXTENSIONS == *" $extension "* ]]; then
    check_audio "$file" "$extension"
  elif [[ -z $extension || $ARTWORK_EXTENSIONS != *" $extension "* ]]; then
    printf '%s: type: neither audio nor artwork\n' "$file"
  fi
  return 0
}

# Prints the lines of check_file for the given file $1, from CACHED if it contains the results of
# the given version $2, and caches any results it computes.
check_file_cached () {
  local file=$1 key=${HASHES[$1]}$'\t'$2 output line results=''
  if [[ -v CACHED[$key] ]]; then
    print_cached "$file" "$key"
    return 0
  fi
  output=$(check_file "$file")
  if [[ -n $output ]]; then
    printf '%s\n' "$output"
    # The cache stores each line sans its "path: " prefix, which `#"$file: "` removes
    while IFS= read -r line; do
      results+=${line#"$file: "}$'\n'
    done <<< "$output"
  fi
  # `%$'\n'` removes the final newline
  record "$file" "$2" "${results%$'\n'}"
  return 0
}

# Invokes check_file_cached with the given version $1 on each NUL-delimited path on stdin, as up to
# JOBS background jobs at once.
check_each_file () {
  local file running=0
  while IFS= read -r -d '' file; do
    check_file_cached "$file" "$1" &
    # wait -n waits for any one job to finish, which frees a slot
    if ((++running >= JOBS)); then
      wait -n
      running=$((running - 1))
    fi
  done
  wait
}

# Lowers the CPU and I/O priority of this process and so of every command it executes, which
# leaves the desktop responsive while the checks occupy the remaining cores.
lower_priority () {
  renice -n 19 -p $$ > /dev/null 2>&1 || true
  # Class 3 (idle) receives disk time only when no other process requests it
  ionice -c 3 -p $$ > /dev/null 2>&1 || true
}

main () {
  local -a paths=()
  local work results
  while (($#)); do
    case $1 in
      -s | --skip)
        (($# >= 2)) || {
          usage >&2
          return 2
        }
        SKIP+=("$2")
        shift 2
        ;;
      -h | --help)
        usage
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        usage >&2
        return 2
        ;;
      *)
        paths+=("$1")
        shift
        ;;
    esac
  done
  ((${#paths[@]})) || {
    usage >&2
    return 2
  }

  # 1. Validate the tools and paths, and compute both cache versions.
  local tool path resolved
  for tool in clamscan ffmpeg file flac; do
    command -v "$tool" > /dev/null || die "$tool is not installed"
  done
  for path in "${paths[@]}"; do
    [[ -e $path ]] || die 'a PATH does not exist'
  done
  # realpath -s makes every path absolute sans resolving symlinks, so --skip globs match the
  # paths as given
  resolved=$(realpath -s -- "${paths[@]}") || die 'realpath failed'
  mapfile -t paths <<< "$resolved"
  local clamscan_version malware_version files_version
  clamscan_version=$(clamscan --version) || die 'clamscan --version failed'
  warn_old_signatures "$clamscan_version"
  malware_version=malware:$clamscan_version
  files_version=$(files_version)

  # 2. List the files to check.
  work=$(mktemp -d) || die 'mktemp failed'
  # shellcheck disable=SC2064 # $work is expanded now, as intended
  trap "rm -r -- '$work'" EXIT
  list_files "${paths[@]}" > "$work/files"
  [[ -s $work/files ]] || return 0

  # 3. Hash every file and load the cached results of both versions.
  local -A HASHES=() CACHED=()
  load_hashes "$work/files"
  mkdir -p -- "${CACHE_FILE%/*}" || die 'creating the cache folder failed'
  load_cache "$malware_version" "$files_version"

  # 4. Execute the checks, and sort their lines so that each file's lines are adjacent.
  results=$({
    check_malware "$work/files" "$malware_version" "$work/clamscan-list"
    check_each_file "$files_version" < "$work/files"
  } | LC_ALL=C sort) || exit 2
  [[ -n $results ]] || return 0
  printf '%s\n' "$results"

  # 5. Fail if any line lacks the warning suffix.
  if grep -q -v -F -e "$WARNING_SUFFIX" <<< "$results"; then
    return 1
  fi
  return 0
}

# stop here if being sourced
return 2> /dev/null

set -euo pipefail

lower_priority
main "$@"
