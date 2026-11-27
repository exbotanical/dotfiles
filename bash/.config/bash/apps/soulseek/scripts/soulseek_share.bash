#!/usr/bin/env bash
# Rebuilds the Soulseek share as symlinks to the beets albums an allowlist selects. Each allowlist
# line is a beets query; an album is shared when any line matches it and no line starting with "!"
# does. The share mirrors the library's Artist/Album layout, so a link to an album that beets has
# since renamed is replaced on the next run. Regular files in the share are never touched. Albums
# the run would add must first pass soulseek_check; otherwise the run changes nothing.

readonly SOULSEEK_DIR=${SOULSEEK_DIR:-$HOME/soulseek}
readonly ALLOWLIST=${SOULSEEK_ALLOWLIST:-$SOULSEEK_DIR/allowlist}
readonly SHARE_DIR=${SOULSEEK_SHARE:-$SOULSEEK_DIR/share}

die () {
  printf 'soulseek_share: %s\n' "$@" >&2
  exit 1
}

usage () {
  cat << EOF
Usage: soulseek_share [-n] [-s GLOB]... [-h]

Makes $SHARE_DIR contain exactly the albums that $ALLOWLIST selects, as symlinks named
Artist/Album like the library. Share that directory in Nicotine+, then use Rescan Shares.

Before adding albums, runs soulseek_check on them. If any file fails a check, prints the failures
and changes nothing: fix or remove the files, or rerun with -s for the files to share as they are.
Albums already in the share are not checked again.

  -n               show the links that would be added and removed, and change nothing; runs no checks
  -s, --skip GLOB  do not check files whose path matches GLOB (see soulseek_check -h); repeatable,
                   e.g. -s '*/Some Album (1999)/*.mp4'
  -h               show this help

Allowlist: one beets query per line; blank lines and lines starting with # are ignored.
  albumartist:"Nurse With Wound"            every album by that artist
  albumartist:Godz album::^Contact           :: makes the value a regular expression
  year:1968..1975 country:DE                 terms on one line must all match
  label:"ReR Megacorp" , label:Recommended   a lone , between terms means or
  category:noise label_type:independent      fields stored by the library classification
  !album::(?i)live                           a leading ! removes matching albums

Quoting: a line is split into terms as a shell splits words. Quote a value that contains spaces,
&, or an apostrophe, and put no space after the colon: albumartist:"Amos & Sara",
albumartist:"Guns N' Roses". A line with an unmatched quote, no terms, or a field without a value
(albumartist:) stops the run, because beets matches every album to those. On the command line,
put the whole term in single quotes, without inner quotes: beet ls -a 'albumartist:Amos & Sara'.

category is one of krautrock, cassette, noise, jungle, other; label_type is one of
independent, diy, major, major-distributed, unknown. See 'beet help query' for the syntax.
EOF
}

# Splits query line $1 as a shell would into the array named $2. Fails on an unmatched quote, on
# a line without terms, and on a term that names a field without a value, such as "albumartist:",
# because beets matches every album to an empty query or an empty value.
query_words () {
  local -n words_=$2
  local word
  mapfile -d '' -t words_ < <(xargs -r printf '%s\0' <<< "$1" 2> /dev/null)
  wait $! || return 1
  ((${#words_[@]})) || return 1
  for word in "${words_[@]}"; do
    [[ $word =~ ^[^:]+::?$ ]] && return 1
  done
  return 0
}

# Prints the album directories the allowlist selects, after removing those its ! lines match.
selected_dirs () {
  local line matches dir
  local -a words
  local -A allowed=() denied=()
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line#"${line%%[![:space:]]*}"}
    [[ -z $line || $line == '#'* ]] && continue
    query_words "${line#!}" words || die "unmatched quote, no terms, or a field without a value: $line"
    matches=$(beet ls -a -p "${words[@]}") || die "beets rejected the query: $line"
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

# Runs soulseek_check with the arguments given and fails when a file fails a check.
check_albums () {
  local status=0
  soulseek_check "$@" || status=$?
  case $status in
    0) return 0 ;;
    1)
      printf 'soulseek_share: the files above failed the checks, so nothing changed; fix them, or rerun with --skip GLOB to share them as they are\n' >&2
      return 1
      ;;
    *) die "soulseek_check exited with status $status" ;;
  esac
}

main () {
  local dry_run='' library selected dir rel link target
  local -a check_args=() new_dirs=()
  local -A wanted=()
  while (($#)); do
    case $1 in
      -n)
        dry_run=1
        shift
        ;;
      -s | --skip)
        (($# >= 2)) || {
          usage >&2
          return 2
        }
        check_args+=(--skip "$2")
        shift 2
        ;;
      -h)
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

  for rel in "${!wanted[@]}"; do
    link=$SHARE_DIR/$rel
    [[ -L $link && $(readlink "$link") == "${wanted[$rel]}" ]] || new_dirs+=("${wanted[$rel]}")
  done
  if [[ -z $dry_run ]] && ((${#new_dirs[@]})); then
    check_albums "${check_args[@]}" -- "${new_dirs[@]}" || exit 1
  fi

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
