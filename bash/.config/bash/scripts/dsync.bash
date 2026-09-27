#!/usr/bin/env bash
#desc           :Sync a directory with its counterpart on a remote host over SSH.
#author         :Matthew Zito
#===============================================================================

# Not readonly: the shpec suite sources every script into one shell, where
# another script's PROG/VERSION assignment would fail against a readonly.
PROG=${0##*/}
VERSION=0.1.0

readonly DEFAULT_EXCLUDES=(
  '.DS_Store'
  '.git/index.lock'
  '.idea'
  'build'
  'cdk.out'
  'dist'
  'node_modules'
  'out'
  'target'
)

readonly RSYNC_FLAGS=(
  --archive
  --compress
  --human-readable
  --itemize-changes
  --partial
)

# %C hashes the connection tuple, keeping the socket path inside the 108 byte
# limit that a long $HOME plus a remote hostname blows past.
readonly SSH_FLAGS=(
  -o ControlMaster=auto
  -o "ControlPath=${XDG_RUNTIME_DIR:-/tmp}/dsync-%C"
  -o ControlPersist=10m
)

readonly IGNORE_FILE_NAME=.dsyncignore

usage () {
  cat <<END
Sync a directory with its counterpart on a remote host, via rsync over SSH.

Usage:
  $PROG [opt...] push|pull LOCAL_DIR [REMOTE_DIR]

Commands:
  push        copy LOCAL_DIR -> REMOTE_DIR (local side wins)
  pull        copy REMOTE_DIR -> LOCAL_DIR (remote side wins)

Options:
  -H HOST     remote host (default: \$DSYNC_HOST, else \$REMOTE_HOSTNAME)
  -R ROOT     remote parent dir used when REMOTE_DIR is omitted
              (default: \$DSYNC_REMOTE_ROOT, else \$REMOTE_SYNCPATH)
  -i FILE     read extra exclude patterns from FILE, one per line
              (default: LOCAL_DIR/$IGNORE_FILE_NAME, when present)
  -n          dry run: report what would change, transfer nothing
  -y          assume yes; skip the --delete confirmation prompt
  --delete    remove destination entries that no longer exist on the source
  --help      show this message and exit
  --version   show the program version and exit

REMOTE_DIR defaults to ROOT/<basename of LOCAL_DIR>. Both sides are always
treated as directories: source contents are synced into the destination
rather than nested beneath it.

Examples:
  $PROG push ~/work/MyPackage
  $PROG pull ~/work/MyPackage /home/myuser/sync/MyPackage
  $PROG -H other-host.amazon.com --delete push ~/work/MyPackage
END
}

sourced? () {
  [[ ${FUNCNAME[1]:-} == source ]]
}

panic () {
  printf '[-] %s\n' "$*" >&2
  exit 1
}

# remote_dir_for resolves the remote counterpart of a local directory, mapping
# it to ROOT/<basename> whenever an explicit remote directory is not given.
remote_dir_for () {
  local local_dir=${1%/}
  local explicit=${2:-}
  local root=${3:-}

  [[ -n $explicit ]] && {
    printf '%s\n' "${explicit%/}"
    return
  }

  [[ -n $root ]] || panic 'no remote directory given and no remote root set; pass REMOTE_DIR or set -R/$DSYNC_REMOTE_ROOT'

  printf '%s\n' "${root%/}/${local_dir##*/}"
}

# rsh_command prints the rsync --rsh value, joining the ssh flags on spaces
# regardless of the caller's IFS.
rsh_command () {
  local IFS=' '

  printf 'ssh %s\n' "${SSH_FLAGS[*]}"
}

# endpoints_for prints the rsync source then destination for a direction, with
# the trailing slashes that make rsync sync contents rather than the dir itself.
endpoints_for () {
  local direction=$1
  local host=$2
  local local_dir=${3%/}
  local remote_dir=${4%/}

  case $direction in
    push ) printf '%s\n' "$local_dir/" "$host:$remote_dir/" ;;
    pull ) printf '%s\n' "$host:$remote_dir/" "$local_dir/"  ;;
    *    ) panic "unknown direction: $direction"             ;;
  esac
}

# exclude_flags prints an rsync --exclude flag per default pattern and per
# non-empty, non-comment line of the ignore file, when one exists.
exclude_flags () {
  local ignore_file=${1:-}
  local pattern

  for pattern in "${DEFAULT_EXCLUDES[@]}"; do
    printf -- '--exclude=%s\n' "$pattern"
  done

  [[ -r $ignore_file ]] || return 0

  while read -r pattern; do
    [[ -z $pattern || $pattern == '#'* ]] && continue
    printf -- '--exclude=%s\n' "$pattern"
  done <"$ignore_file"
}

make_dest_dir () {
  local direction=$1
  local host=$2
  local local_dir=$3
  local remote_dir=$4

  case $direction in
    push ) ssh "${SSH_FLAGS[@]}" "$host" mkdir -p "'$remote_dir'" ;;
    pull ) mkdir -p "$local_dir"                                 ;;
  esac
}

# confirm_deletions prompts before a --delete run, listing the entries the
# destination would lose. Refuses to guess when stdin is not a terminal.
confirm_deletions () {
  local preview
  local deletions
  local reply

  preview=$("$@" --dry-run)
  deletions=$(grep '^\*deleting' <<<"$preview" || true)

  [[ -n $deletions ]] || return 0

  printf '[*] %s will be removed from the destination:\n%s\n' "$(wc -l <<<"$deletions")" "$deletions"

  [[ -t 0 ]] || panic 'refusing to delete without a terminal to confirm on; re-run with -y'

  read -r -p '[?] proceed? [y/N] ' reply
  [[ $reply == [yY]* ]] || panic 'aborted'
}

main () {
  local direction=$1
  local local_dir=${2%/}
  local remote_dir_arg=${3:-}

  [[ -d $local_dir ]] || panic "not a directory: $local_dir"

  local host=${HOST_FLAG:-${DSYNC_HOST:-${REMOTE_HOSTNAME:-}}}
  [[ -n $host ]] || panic 'no remote host set; pass -H or set $DSYNC_HOST'

  local remote_dir
  remote_dir=$(remote_dir_for "$local_dir" "$remote_dir_arg" "${ROOT_FLAG:-${DSYNC_REMOTE_ROOT:-${REMOTE_SYNCPATH:-}}}")

  local ignore_file=${IGNORE_FLAG:-$local_dir/$IGNORE_FILE_NAME}

  local -a excludes
  mapfile -t excludes < <(exclude_flags "$ignore_file")

  local -a endpoints
  mapfile -t endpoints < <(endpoints_for "$direction" "$host" "$local_dir" "$remote_dir")

  local -a cmd=(
    rsync
    "${RSYNC_FLAGS[@]}"
    --rsh="$(rsh_command)"
    "${excludes[@]}"
  )

  (( DELETE_FLAG )) && cmd+=( --delete )

  cmd+=( "${endpoints[@]}" )

  printf '[*] %s: %s -> %s\n' "$direction" "${endpoints[0]}" "${endpoints[1]}"

  (( DRY_RUN_FLAG )) && {
    "${cmd[@]}" --dry-run
    return
  }

  (( DELETE_FLAG && !YES_FLAG )) && confirm_deletions "${cmd[@]}"

  make_dest_dir "$direction" "$host" "$local_dir" "$remote_dir"
  "${cmd[@]}"
}

sourced? && return

set -euo pipefail

DELETE_FLAG=0
DRY_RUN_FLAG=0
YES_FLAG=0

while [[ ${1:-} == -* ]]; do
  case $1 in
    -H       ) HOST_FLAG=${2:-};   shift 2 ;;
    -R       ) ROOT_FLAG=${2:-};   shift 2 ;;
    -i       ) IGNORE_FLAG=${2:-}; shift 2 ;;
    -n       ) DRY_RUN_FLAG=1;     shift   ;;
    -y       ) YES_FLAG=1;         shift   ;;
    --delete ) DELETE_FLAG=1;      shift   ;;
    --help   ) usage; exit 0                ;;
    --version) printf '%s version %s\n' "$PROG" "$VERSION"; exit 0 ;;
    *        ) usage >&2; panic "unknown option: $1" ;;
  esac
done

case $# in
  2|3 ) ;;
  *   ) usage >&2; exit 1 ;;
esac

main "$@"
