#!/usr/bin/env bash
# Runs the batch checks of autodidact's miscellaneous/SOULSEEK_GUIDE.md (section 10) on music
# files: a ClamAV scan, a file type allowlist, the real type of each audio file, a full decode,
# `flac -t` on FLAC files, and a test for lossless files decoded from a lossy encoding. Prints one
# line per failed check or warning and changes no file.

readonly AUDIO_EXTENSIONS=' flac mp3 m4a ogg opus wav aiff '
readonly ARTWORK_EXTENSIONS=' jpg jpeg png cue log txt '
readonly LOSSLESS_EXTENSIONS=' flac wav aiff '
# Lowercase patterns for the descriptions `file` gives each audio format.
readonly AUDIO_TYPES='audio|flac|mpeg|ogg|wave|iso media'
readonly INCOMPLETE_DIR=${SOULSEEK_INCOMPLETE:-$HOME/Downloads/soulseek/incomplete}
readonly SIGNATURE_MAX_AGE_DAYS=3
# A few damaged frames in a file that otherwise decodes are inaudible (an MP3 frame is about
# 26 ms), so up to MAX_DAMAGED_FRAMES of them are a warning.
readonly MAX_DAMAGED_FRAMES=50
readonly WARNING_SUFFIX=' (warning)'
JOBS=$(nproc)
readonly JOBS

# A lossy encoder's lowpass filter leaves a drop of CUTOFF_DROP_DB or more between two adjacent
# 1 kHz bands. A quiet upper range, as in drone music, is no such drop, so the band below the drop
# must be louder than AUDIBLE_DB. The bands stop at 20 kHz because a genuine CD's anti-alias
# filter also drops steeply above it, and files below MIN_SAMPLE_RATE are not tested because
# their Nyquist frequency falls inside the bands.
readonly BAND_EDGES=(13000 14000 15000 16000 17000 18000 19000 20000)
readonly CUTOFF_DROP_DB=30
readonly AUDIBLE_DB=-90
readonly MIN_SAMPLE_RATE=44100

# Globs from --skip, matched against each file's absolute path.
SKIP=()

die () {
  printf 'soulseek_check: %s\n' "$@" >&2
  exit 2
}

usage () {
  cat << EOF
Usage: soulseek_check [-s GLOB]... PATH...

Checks every file under each PATH (files or directories, followed through symlinks) and prints
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

Files under $INCOMPLETE_DIR are not checked.
EOF
}

# Succeeds when the path $1 matches a --skip glob.
skipped () {
  local glob
  for glob in "${SKIP[@]}"; do
    # shellcheck disable=SC2053
    [[ $1 == $glob ]] && return 0
  done
  return 1
}

# Prints, NUL-terminated, each file under the paths given, except skipped files and partial downloads.
list_files () {
  local file
  while IFS= read -r -d '' file; do
    skipped "$file" || printf '%s\0' "$file"
  done < <(find -L "$@" -path "$INCOMPLETE_DIR" -prune -o -type f -print0)
}

# Reports on stderr when the ClamAV signatures are older than SIGNATURE_MAX_AGE_DAYS.
warn_old_signatures () {
  local version built age
  version=$(clamscan --version) || die 'clamscan --version failed'
  built=$(date -d "${version##*/}" +%s 2> /dev/null) || return 0
  age=$((($(date +%s) - built) / 86400))
  ((age <= SIGNATURE_MAX_AGE_DAYS)) \
    || printf 'soulseek_check: the ClamAV signatures are %s days old; run sudo freshclam\n' "$age" >&2
}

# Prints a malware line for each file in the newline-separated list file $1 that ClamAV flags.
check_malware () {
  local output status=0 line
  output=$(clamscan --infected --no-summary --file-list="$1") || status=$?
  ((status <= 1)) || die "clamscan exited with status $status"
  while IFS= read -r line; do
    [[ $line == *' FOUND' ]] || continue
    line=${line% FOUND}
    printf '%s: malware: %s\n' "${line%: *}" "${line##*: }"
  done <<< "$output"
}

# Prints the ffmpeg filter graph that measures the RMS level of each band between BAND_EDGES.
band_graph () {
  local i graph outputs='' count=$((${#BAND_EDGES[@]} - 1))
  graph="[0:a]aformat=sample_fmts=fltp:channel_layouts=mono,asplit=$count"
  for ((i = 0; i < count; i++)); do
    graph+="[s$i]"
  done
  for ((i = 0; i < count; i++)); do
    graph+=";[s$i]firequalizer=gain='if(between(f,${BAND_EDGES[i]},${BAND_EDGES[i + 1]}),0,-200)'"
    graph+=":delay=0.05:accuracy=1:wfunc=nuttall"
    graph+=",astats@b${BAND_EDGES[i]}=measure_overall=RMS_level:measure_perchannel=none[o$i]"
    outputs+="[o$i]"
  done
  printf '%s;%samix=inputs=%s[out]' "$graph" "$outputs" "$count"
}

# Prints "rate HZ" for each audio stream of the file $1, then "EDGE LEVEL" for each band, where
# LEVEL is the band's RMS level in dBFS over the whole file.
band_levels () {
  ffmpeg -nostdin -hide_banner -nostats -v info -i "$1" -filter_complex "$(band_graph)" \
    -map '[out]' -f null - 2>&1 \
    | sed -n -E \
      -e 's/^ *Stream #0:[0-9]+[^:]*: Audio: [^,]*, ([0-9]+) Hz.*/rate \1/p' \
      -e 's/^\[astats@b([0-9]+) @ [^]]*\] RMS level dB: (.*)$/\1 \2/p'
}

# Reads band_levels output and prints "N dB drop at K kHz" for the steepest drop between adjacent
# bands when it is a lossy cutoff by the thresholds above. Prints nothing otherwise.
cutoff () {
  sort -n | awk -v drop_db="$CUTOFF_DROP_DB" -v audible_db="$AUDIBLE_DB" -v min_rate="$MIN_SAMPLE_RATE" '
    $1 == "rate" { if (rate == "") rate = $2; next }
    {
      level = ($2 ~ /^-?[0-9]+(\.[0-9]+)?$/) ? $2 + 0 : -200
      if (bands++ && previous > audible_db && previous - level > drop) {
        drop = previous - level
        edge = $1
      }
      previous = level
    }
    END { if (rate + 0 >= min_rate && drop >= drop_db) printf "%d dB drop at %d kHz\n", drop, edge / 1000 }
  '
}

# Prints a decode line for the file $1 when ffmpeg cannot decode it or finds damaged frames in it.
# ffmpeg prints "Error submitting packet to decoder" once per damaged frame; the repeat flag
# stops it from folding identical lines into "Last message repeated" lines. Other error output
# counts one frame per line.
check_decode () {
  local errors damaged unit=frames suffix=$WARNING_SUFFIX
  if ! errors=$(ffmpeg -nostdin -v repeat+error -i "$1" -f null - 2>&1 > /dev/null); then
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

# Prints a line for each check of the audio checks that the file $1, of extension $2, fails.
check_audio () {
  local file=$1 extension=$2 type drop
  type=$(file -b -- "$file")
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

# Prints a line for each check that the file $1 fails, other than the malware check.
check_file () {
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

# Runs check_file on each NUL-terminated path on stdin, JOBS files at a time.
check_each_file () {
  local file running=0
  while IFS= read -r -d '' file; do
    check_file "$file" &
    if ((++running >= JOBS)); then
      wait -n
      running=$((running - 1))
    fi
  done
  wait
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

  local tool path resolved
  for tool in clamscan ffmpeg file flac; do
    command -v "$tool" > /dev/null || die "$tool is not installed"
  done
  for path in "${paths[@]}"; do
    [[ -e $path ]] || die 'a PATH does not exist'
  done
  resolved=$(realpath -s -- "${paths[@]}") || die 'realpath failed'
  mapfile -t paths <<< "$resolved"
  warn_old_signatures

  work=$(mktemp -d) || die 'mktemp failed'
  # shellcheck disable=SC2064
  trap "rm -r -- '$work'" EXIT
  list_files "${paths[@]}" > "$work/files"
  [[ -s $work/files ]] || return 0
  tr '\0' '\n' < "$work/files" > "$work/clamscan-list"

  results=$({
    check_malware "$work/clamscan-list"
    check_each_file < "$work/files"
  } | LC_ALL=C sort) || exit 2
  [[ -n $results ]] || return 0
  printf '%s\n' "$results"
  # A line without the warning suffix is a failure.
  if grep -q -v -F -e "$WARNING_SUFFIX" <<< "$results"; then
    return 1
  fi
  return 0
}

# stop here if being sourced
return 2> /dev/null

set -euo pipefail

main "$@"
