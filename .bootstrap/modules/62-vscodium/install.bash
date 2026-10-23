# Installs the pinned VSCodium extensions that are not installed at their pinned version.
installed=$(codium --list-extensions --show-versions)
while IFS= read -r extension; do
  if grep -qixF -- "$extension" <<< "$installed"; then
    log "[=] $extension"
  else
    codium --install-extension "$extension"
  fi
done < <(bootstrap::packages vscodium)
