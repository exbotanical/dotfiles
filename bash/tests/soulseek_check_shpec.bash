RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"
TestRoot=$(mktemp -d)
Script=$RootDir/../.config/bash/apps/soulseek/scripts/soulseek_check.bash
export SOULSEEK_INCOMPLETE=$TestRoot/downloads/incomplete
export SOULSEEK_CACHE=$TestRoot/cache

source "$RootDir/../../.test/shpec_utils.bash"
source "$Script"

# Band levels ffmpeg measured on test signals: pink noise as FLAC, the same noise through a
# 128 kbit/s MP3 and back, and a 110 Hz drone with three harmonics.
export GenuineBands=$'20000 -47.6\n19000 -47.3\n18000 -47.2\n17000 -46.9\n16000 -46.7\n15000 -46.4\n14000 -46.1\n13000 -45.8'
export TranscodeBands=$'19000 -104.7\n18000 -103.9\n17000 -102.1\n16000 -49.7\n15000 -46.8\n14000 -46.4\n13000 -46.2'

# Fakes of the tools. Each judges a file by its content: a marker word (virus, text, corrupt,
# transcode) or "damaged N" for a file with N damaged frames. They are exported so that the
# script, executed as its own process, calls them.
# CLAM_SIGNATURES and FFMPEG_VERSION set the versions they report; CLAM_FLAGS sets the marker word
# clamscan flags, and FFMPEG_BROKEN=1 makes every decode fail.
clamscan () {
  local file
  if [[ $1 == --version ]]; then
    printf "ClamAV 1.5.4/%s/%s\\n" "${CLAM_SIGNATURES:-28194}" "$(date "+%a %b %e 00:00:00 %Y")"
    return 0
  fi
  while IFS= read -r file; do
    if grep -q "${CLAM_FLAGS:-virus}" "$file"; then printf '%s: Eicar-Test-Signature FOUND\n' "$file"; fi
  done < "${3#--file-list=}"
  return 0
}
file () {
  if [[ $1 == --version ]]; then
    printf 'file-5.46\nmagic file from /usr/share/file/misc/magic\n'
  elif grep -q text "$3"; then
    printf 'ASCII text\n'
  else
    printf 'FLAC audio bitstream data\n'
  fi
}
ffmpeg () {
  local input word count bands
  if [[ $1 == -version ]]; then
    printf 'ffmpeg version %s\nbuilt with gcc 15\n' "${FFMPEG_VERSION:-8.0}"
    return 0
  fi
  while [[ $1 != -i ]]; do shift; done
  input=$2
  [[ -n ${FFMPEG_BROKEN:-} ]] && return 234
  grep -q corrupt "$input" && return 234
  if [[ $* != *-filter_complex* ]]; then
    read -r word count < "$input"
    [[ $word == damaged ]] || return 0
    for ((; count > 0; count--)); do
      printf '[aist#0:0/mp3 @ 0x5555] Error submitting packet to decoder: Invalid data found\n' >&2
    done
    return 0
  fi
  printf '  Stream #0:0: Audio: flac, 44100 Hz, stereo, s16\n' >&2
  if grep -q transcode "$input"; then bands=$TranscodeBands; else bands=$GenuineBands; fi
  while read -r word count; do
    printf '[astats@b%s @ 0x5555] RMS level dB: %s\n' "$word" "$count" >&2
  done <<< "$bands"
}
flac () {
  if [[ $1 == --version ]]; then
    printf 'flac 1.5.0\n'
    return 0
  fi
  ! grep -q corrupt "$4"
}
export -f clamscan file ffmpeg flac

# Writes each given "path:content" argument $@ as a file in TestRoot
make_files () {
  local spec
  for spec; do
    mkdir -p "$(dirname "$TestRoot/${spec%%:*}")"
    printf '%s\n' "${spec#*:}" > "$TestRoot/${spec%%:*}"
  done
}

describe 'soulseek_check'
  describe 'cutoff'
    it 'reports a steep drop below an audible band and passes gradual or inaudible spectra'
      result=$(
        for levels in "rate 44100"$'\n'"$GenuineBands" \
          "rate 44100"$'\n'"$TranscodeBands" \
          $'rate 44100\n19000 -110.1\n18000 -109.3\n17000 -110.2\n16000 -108.1\n15000 -109.9\n14000 -108.9\n13000 -108.0' \
          $'rate 44100\n19000 -99.5\n18000 -88.5\n17000 -79.5\n16000 -72.3\n15000 -66.0\n14000 -60.7\n13000 -56.4' \
          $'rate 44100\n19000 -111.8\n18000 -108.6\n17000 -53.9\n16000 -47.4\n15000 -47.0\n14000 -46.6\n13000 -46.4' \
          $'rate 22050\n19000 -inf\n18000 -inf\n17000 -inf\n16000 -inf\n15000 -40.0\n14000 -40.0\n13000 -40.0'; do
          printf '[%s]' "$(cutoff <<< "$levels")"
        done
      )
      assert equal '[][52 dB drop at 17 kHz][][][54 dB drop at 18 kHz][]' "$result"
    ti
  end_describe

  # These execute the script as its own process; they are therefore subject to its set -euo pipefail
  describe 'the script'
    alias setup='rm -rf "$TestRoot/downloads" "$SOULSEEK_CACHE"'

    it 'prints one sorted line per failed check and per warning, and exits 1 on a failure'
      d=$TestRoot/downloads/album
      make_files downloads/album/01.flac:ok downloads/album/02.flac:corrupt \
        downloads/album/03.flac:transcode downloads/album/04.mp3:transcode downloads/album/05.mp3:text \
        downloads/album/06.mp3:virus downloads/album/setup.exe:ok downloads/album/README:ok \
        downloads/album/cover.JPG:ok downloads/album/notes.txt:text downloads/incomplete/x.flac:corrupt \
        'downloads/album/07.mp3:damaged 1' 'downloads/album/08.mp3:damaged 51'
      output=$(bash "$Script" "$TestRoot/downloads")
      assert equal "1 $d/02.flac: decode: ffmpeg cannot decode the file
$d/02.flac: flac: flac -t reports an error
$d/03.flac: transcode: 52 dB drop at 17 kHz
$d/05.mp3: content: ASCII text
$d/06.mp3: malware: Eicar-Test-Signature
$d/07.mp3: decode: 1 damaged frame (warning)
$d/08.mp3: decode: 51 damaged frames
$d/README: type: neither audio nor artwork
$d/setup.exe: type: neither audio nor artwork" "$? $output"
    ti

    it 'exits 0 when the only findings are warnings'
      d=$TestRoot/downloads/album
      make_files downloads/album/01.flac:ok 'downloads/album/02.mp3:damaged 50'
      output=$(bash "$Script" "$d")
      assert equal "0 $d/02.mp3: decode: 50 damaged frames (warning)" "$? $output"
    ti

    it 'follows symlinked album folders and exits 0 when every file passes'
      make_files library/album/01.flac:ok library/album/cover.jpg:ok
      mkdir -p "$TestRoot/downloads/share"
      ln -s "$TestRoot/library/album" "$TestRoot/downloads/share/album"
      output=$(bash "$Script" "$TestRoot/downloads/share")
      assert equal '0 ' "$? $output"
    ti

    it 'does not check files that a --skip glob matches'
      make_files downloads/album/01.flac:corrupt downloads/album/video.mp4:ok downloads/album/02.flac:ok
      output=$(bash "$Script" --skip '*/01.flac' -s '*.mp4' "$TestRoot/downloads/album")
      assert equal '0 ' "$? $output"
    ti

    it 'reuses the cached results of an unchanged file and checks a changed one'
      d=$TestRoot/downloads/album
      make_files downloads/album/01.flac:ok downloads/album/02.flac:corrupt
      first=$(bash "$Script" "$d")
      printf 'changed\n' >> "$d/01.flac"
      printf 'ok\n' > "$d/02.flac"
      second=$(FFMPEG_BROKEN=1 bash "$Script" "$d")
      status=$?
      assert equal "$d/02.flac: decode: ffmpeg cannot decode the file
$d/02.flac: flac: flac -t reports an error|1 $d/01.flac: decode: ffmpeg cannot decode the file" "$first|$status $second"
    ti

    it 'checks every file again when the ClamAV signatures or a tool version change'
      d=$TestRoot/downloads/album
      make_files downloads/album/01.flac:virus
      result=$(for run in 'CLAM_FLAGS=none' 'CLAM_FLAGS=virus' 'CLAM_FLAGS=virus CLAM_SIGNATURES=28195' \
        'FFMPEG_BROKEN=1' 'FFMPEG_BROKEN=1 FFMPEG_VERSION=8.1'; do
        printf '[%s]' "$(env $run bash "$Script" "$d" | sed "s|$d/||")"
      done)
      assert equal '[][][01.flac: malware: Eicar-Test-Signature][01.flac: malware: Eicar-Test-Signature][01.flac: decode: ffmpeg cannot decode the file
01.flac: malware: Eicar-Test-Signature]' "$result"
    ti

    it 'exits 2 without a path, on an unknown option, or for a missing path'
      result=$(bash "$Script" > /dev/null 2>&1; printf '%s ' $?; bash "$Script" -x . > /dev/null 2>&1; printf '%s ' $?
        bash "$Script" "$TestRoot/none" > /dev/null 2>&1; printf '%s' $?)
      assert equal '2 2 2' "$result"
    ti
  end_describe
end_describe

rm -rf "$TestRoot"
