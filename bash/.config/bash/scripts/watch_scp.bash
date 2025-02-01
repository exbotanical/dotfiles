#!/usr/bin/env bash

source "$(dirname "$(readlink -f "$BASH_SOURCE")")/../lib/utils.bash"
source "$(dirname "$(readlink -f "$BASH_SOURCE")")/../lib/parser.bash"

utils::globbing off
utils::splitspace off

PROG=$0

usage () {
  cat <<END
Monitor a directory and copy files to a host.

Usage:
  $PROG [opt] DIRECTORY PATTERN[|PATTERN|...] REMOTE_HOST

Options:
  -p PERIOD   number of seconds between checks (default: 360)
  --help      show this message and exit
  --version   show the program version and exit

Arguments:
  DIRECTORY   the directory to monitor

  PATTERN     file pattern of files to transfer. multiple patterns
              can be separated with a |

  REMOTE      remote location formatted as [<user>@]<server>:<dir>

Check DIRECTORY for new files matching PATTERN(s)
every PERIOD seconds. When new files are discovered, transfer
them to a remote host.
END
  exit 1
}

LOCKFILE=/dev/shm/$PROG-lockfile
PROCESSED_FILE=/tmp/$PROG-transferred

declare -i PERIOD=5*60
VERSION=0.0.1

HELP_FLAG=0
TRACE_FLAG=0
VERSION_FLAG=0

panic () {
  echo $1
  exit 1
}

blank? () {
  [[ -z ${1:-} ]]
}

# list lists files matching a series of | delimited glob patterns
list () { (
  cd $1
  # Don't return the pattern if it doesn't evaluate to anything
  shopt -s nullglob
  # Turn on extended globs to support | in regex
  shopt -s extglob
  set +o noglob
  # Use eval to defer execution until extglob is on
  eval "set -- +($2)"
  echo "$*"
) }

# newitems diffs two newline-delimited lists
newitems () {
  # Mitigate edgecase whereby comm exits the pipeline if no result
  blank? $2 && return
  # Use process substitution
  comm -13 <(echo "$1") <(echo "$2")
}

busy? () {
  fuser $DIR/$1 &>/dev/null
}

not_busy () {
  local file

  while read -r file; do
    ! busy? $file && echo $file
  done;:
}

lockfile? () {
  ! (set -o noclobber; write_file $LOCKFILE <<<$$) 2>/dev/null
}

track () { (
  cd $Dir
  md5sum $1 | append_file $PROCESSED_FILE
) }

# transfer reads from stdin and pipe into scp
transfer () {
  local file

  while read -r file; do
    scp $DIR/$file $REMOTE
    track $file
  done;: # Prevent errexit trigger (read returns false)
}

transferred? () { (
  cd $DIR
  grep -q $(md5sum $1) $PROCESSED_FILE
) }

not_transferred () {
  local file

  while read -r file; do
    ! transferred? $file && echo $file
  done;:
}

write_file () {
  cat >$1
}

append_file () {
  cat >>$1
}

running? () {
  [[ -e $LOCKFILE ]] && ps -p $(<$LOCKFILE) >/dev/null
}

singleton? () {
  ! running?   || return
  # rm $LOCKFILE || return
  ! lockfile? && trap "rm $LOCKFILE;"' echo "stopped at $(date)"' EXIT
}

start_monitor () {
  local new_contents
  local old_contents

  old_contents=$(list $DIR $PATTERN_LIST)
  while true; do
    sleep $PERIOD
    new_contents=$(list $DIR $PATTERN_LIST)
    newitems "$old_contents" "$new_contents" | not_busy | not_transferred
    old_contents=$new_contents
  done | transfer;: # Perform transfer in parallel
}

main () {
  touch $DIR/$PROCESSED_FILE

  echo "started at $(date)"
  start_monitor
}

utils::sourced? && return

option_defs=(
  -p,PERIOD
  --help,HELP_FLAG,f
  --version,VERSION_FLAG,f
  --trace,TRACE_FLAG,f
)

# declare -a options
parser::parseopts "$*" "${option_defs[*]}" options pos_args
# shellcheck disable=SC2068
(( ${#options[@]}                    )) && declare ${options[@]}
(( VERSION_FLAG                      )) && panic "$PROG version $VERSION"
(( HELP_FLAG || ${#pos_args[@]} != 3 )) && usage

singleton? || panic 'another instance is running; exiting'

(( TRACE_FLAG )) && set -x

set -- $pos_args
DIR=$1
PATTERN_LIST=$2
REMOTE=$3

SECONDS=0
for (( retries = 0; retries < 10; retries++ )); do
  (
    utils::strict_mode on
    main
  )

  echo 'restarting after error'
  (( SECONDS >= 24*60*60 )) && retries=0
  SECONDS=0
  sleep 10
done

panic 'too many retries; exiting'
