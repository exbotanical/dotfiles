# Installs the pinned VSCodium extensions that are not installed at their pinned version.
readonly OPEN_VSX_API=https://open-vsx.org/api

module::applies () {
  [[ $PROFILE == desktop ]] && has codium
}

module::install () {
  local installed extension
  installed=$(codium --list-extensions --show-versions)
  while IFS= read -r extension; do
    if grep -qixF -- "$extension" <<< "$installed"; then
      log "[=] $extension"
    else
      codium --install-extension "$extension"
    fi
  done < <(bootstrap::packages vscodium)
}

# Reports each pinned extension whose latest Open VSX version differs from its pin. The API serves
# namespace/name for the extension ID namespace.name, and curl fetches them in parallel.
module::outdated () {
  local extension name
  local -a pins args=()
  mapfile -t pins < <(bootstrap::packages vscodium)
  ((${#pins[@]} > 0)) || return 0

  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
  for extension in "${pins[@]}"; do
    name=${extension%@*}
    args+=(-o "$work/$name.json" "$OPEN_VSX_API/${name/.//}")
  done
  curl -sS --parallel --parallel-max 8 "${args[@]}"

  for extension in "${pins[@]}"; do
    name=${extension%@*}
    bootstrap::report_outdated "$name" "${extension##*@}" "$(jq -r '.version // empty' "$work/$name.json" 2> /dev/null)"
  done
}
