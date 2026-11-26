#!/usr/bin/env bash
# Installs every file in the root package as a copy at the same path under TARGET, and deletes
# the files a previous run installed that the package no longer has. Copies, unlike stow's links
# into the repo, exist before a separately mounted /home is, when systemd reads unit drop-ins and
# applies sysctl.d. A link into SOURCE left by the stow install is replaced by the copy. When
# anything changed under / and systemd is running, the systemd units and the sysctl settings are
# reloaded; otherwise systemd reads them when it starts. A run changes nothing when every copy is
# current.
#
# Usage: install-root.bash SOURCE [TARGET] [MANIFEST]
#   SOURCE    the root package directory
#   TARGET    the directory to install into (default: /)
#   MANIFEST  the list of installed paths (default: TARGET/var/lib/dotfiles/root-manifest)

# The stow install linked into these directories, and its links are searched for in them even
# after the package stops having files there.
readonly STOW_DIRS=(etc var)

die () {
  printf '%s\n' "$@" >&2
  exit 1
}

# Prints the path of every file in $1, relative to $1, one per line in sorted order.
package_files () {
  (cd "$1" && find . -type f -printf '%P\n' | LC_ALL=C sort)
}

# Deletes every symbolic link under the directories $3... of $2 that resolves into $1, including
# links whose target no longer exists. Relative stow links name the repo path, so -lname
# preselects them. The search reaches the depth of the deepest package file.
remove_links_into () {
  local source=$1 target=$2 dir link depth
  shift 2
  depth=$(cd "$source" && find . -type f -printf '%d\n' | sort -n | tail -1)
  for dir; do
    [[ -d $target/$dir ]] || continue
    while IFS= read -r -d '' link; do
      [[ $(readlink -m "$link") == "$source"/* ]] || continue
      rm "$link"
      printf 'unlinked %s\n' "${link#"$target"}"
    done < <(find "$target/$dir" -maxdepth "${depth:-1}" -type l -lname "*${source#/}*" -print0)
  done
}

# Copies $1/$3 to $2/$3 with $1/$3's mode, unless the copy is identical.
install_file () {
  local source=$1 target=$2 path=$3
  cmp -s "$source/$path" "$target/$path" && return 0
  install -D -m "$(stat -c %a "$source/$path")" "$source/$path" "$target/$path"
  printf 'installed /%s\n' "$path"
}

# Deletes each path listed in manifest $2 but absent from the package files $3..., unless
# something replaced the installed file with a link.
prune_removed () {
  local target=$1 manifest=$2 path
  shift 2
  [[ -f $manifest ]] || return 0
  while IFS= read -r path; do
    [[ -f $target/$path && ! -L $target/$path ]] || continue
    rm "$target/$path"
    printf 'removed /%s\n' "$path"
  done < <(LC_ALL=C comm -23 "$manifest" <(printf '%s\n' "$@"))
}

# Writes the package files $2... to manifest $1, unless it already lists exactly them.
write_manifest () {
  local manifest=$1
  shift
  cmp -s "$manifest" <(printf '%s\n' "$@") && return 0
  mkdir -p "${manifest%/*}"
  printf '%s\n' "$@" > "$manifest"
}

main () {
  (($# >= 1)) || die 'usage: install-root.bash SOURCE [TARGET] [MANIFEST]'
  local source target manifest changes path
  local -a files dirs
  source=$(realpath "$1")
  target=${2:-/}
  target=${target%/}
  manifest=${3:-$target/var/lib/dotfiles/root-manifest}

  mapfile -t files < <(package_files "$source")
  mapfile -t dirs < <(printf '%s\n' "${STOW_DIRS[@]}" "${files[@]%%/*}" | LC_ALL=C sort -u)
  changes=$(
    remove_links_into "$source" "$target" "${dirs[@]}"
    for path in "${files[@]}"; do
      install_file "$source" "$target" "$path"
    done
    prune_removed "$target" "$manifest" "${files[@]}"
  )
  write_manifest "$manifest" "${files[@]}"

  if [[ -z $changes ]]; then
    printf 'root: every file is current\n'
    return 0
  fi
  printf '%s\n' "$changes"
  # /run/systemd/system exists only when systemd is the running init (sd_booted(3)).
  if [[ -z $target && -d /run/systemd/system ]]; then
    systemctl daemon-reload
    sysctl --quiet --system
  fi
}

# stop here if being sourced
return 2> /dev/null

set -euo pipefail
shopt -s inherit_errexit

main "$@"
