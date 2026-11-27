#!/usr/bin/env bash
# Rebuilds the Soulseek share as symlinks to the beets albums an allowlist selects. Each allowlist
# line is a beets query; an album is shared when any line matches it and no line starting with "!"
# does. The share mirrors the library's Artist/Album layout, so a link to an album that beets has
# since renamed is replaced on the next run. Regular files in the share are never touched.

readonly SOULSEEK_DIR=${SOULSEEK_DIR:-$HOME/soulseek}
readonly ALLOWLIST=${SOULSEEK_ALLOWLIST:-$SOULSEEK_DIR/allowlist}
readonly SHARE_DIR=${SOULSEEK_SHARE:-$SOULSEEK_DIR/share}

die () {
  printf 'soulseek_share: %s\n' "$@" >&2
  exit 1
}

usage () {
  cat << EOF
Usage: soulseek_share [-n] [-h]

Makes $SHARE_DIR contain exactly the albums that $ALLOWLIST selects, as symlinks named
Artist/Album like the library. Share that directory in Nicotine+, then use Rescan Shares.

  -n  show the links that would be added and removed, and change nothing
  -h  show this help

Allowlist: one beets query per line; blank lines and lines starting with # are ignored.
  albumartist:"Nurse With Wound"            every album by that artist
  albumartist:Godz album::^Contact           :: makes the value a regular expression
  year:1968..1975 country:DE                 terms on one line must all match
  label:"ReR Megacorp" , label:Recommended   a lone , between terms means or
  category:noise label_type:independent      fields stored by the library classification
  !album::(?i)live                           a leading ! removes matching albums

category is one of krautrock, cassette, noise, jungle, other; label_type is one of
independent, diy, major, major-distributed, unknown. See 'beet help query' for the syntax.
EOF
}

# Prints the words of query line $1, split as a shell would split them, each followed by NUL.
query_words () {
  xargs printf '%s\0' <<< "$1"
}

# Prints the directory of every album that query line $1 matches, one per line.
album_dirs () {
  local -a words
  mapfile -d '' -t words < <(query_words "$1") || return 1
  beet ls -a -p "${words[@]}"
}

# Prints the album directories the allowlist selects, after removing those its ! lines match.
selected_dirs () {
  local line query matches dir
  local -A allowed=() denied=()
  while IFS= read -r line || [[ -n $line ]]; do
    [[ $line =~ ^[[:space:]]*(#|$) ]] && continue
    query=${line#!}
    matches=$(album_dirs "$query") || die "beets rejected the query: $line"
    if [[ -z $matches ]]; then
      printf 'soulseek_share: no album matches: %s\n' "$line" >&2
      continue
    fi
    while IFS= read -r dir; do
      if [[ $line == '!'* ]]; then denied[$dir]=1; else allowed[$dir]=1; fi
    done <<< "$matches"
  done < "$ALLOWLIST"
  for dir in "${!allowed[@]}"; do
    [[ -n ${denied[$dir]:-} ]] || printf '%s\n' "$dir"
  done
}

main () {
  local opt dry_run='' library selected dir rel link target
  local -A wanted=()
  while getopts ':nh' opt; do
    case $opt in
      n) dry_run=1 ;;
      h)
        usage
        return 0
        ;;
      *)
        usage >&2
        return 2
        ;;
    esac
  done

  [[ -f $ALLOWLIST ]] || die "no allowlist at $ALLOWLIST"
  library=$(beet config | sed -n 's/^directory: //p') || die 'beet config failed'
  library=${library/#\~/$HOME}
  [[ -n $library ]] || die 'beets reports no library directory'

  selected=$(selected_dirs) || exit 1
  while IFS= read -r dir; do
    [[ -z $dir ]] && continue
    [[ $dir == "$library"/* ]] || die "album outside the library: $dir"
    wanted[${dir#"$library"/}]=$dir
  done <<< "$selected"

  mkdir -p "$SHARE_DIR" || die "creating $SHARE_DIR failed"
  while IFS= read -r -d '' link; do
    rel=${link#"$SHARE_DIR"/}
    target=$(readlink "$link")
    [[ ${wanted[$rel]:-} == "$target" ]] && continue
    printf -- '- %s\n' "$rel"
    [[ -n $dry_run ]] || rm "$link" || die "removing $link failed"
  done < <(find "$SHARE_DIR" -type l -print0)

  for rel in "${!wanted[@]}"; do
    link=$SHARE_DIR/$rel
    [[ -L $link && $(readlink "$link") == "${wanted[$rel]}" ]] && continue
    printf '+ %s\n' "$rel"
    [[ -n $dry_run ]] && continue
    mkdir -p "${link%/*}" || die "creating ${link%/*} failed"
    ln -s -- "${wanted[$rel]}" "$link" || die "linking $rel failed"
  done

  [[ -n $dry_run ]] || find "$SHARE_DIR" -mindepth 1 -type d -empty -delete
  if [[ -n $dry_run ]]; then
    printf 'soulseek_share: %s albums would be shared\n' "${#wanted[@]}"
  else
    printf 'soulseek_share: %s albums shared\n' "${#wanted[@]}"
  fi
}

# stop here if being sourced
return 2> /dev/null

set -euo pipefail

main "$@"
