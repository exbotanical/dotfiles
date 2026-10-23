# Installs the cargo package lists with the rustup toolchain.
installed=$(cargo install --list)
while IFS= read -r crate; do
  if [[ $installed == *$'\n'"$crate "* || $installed == "$crate "* ]]; then
    log "[=] $crate"
  else
    cargo install --locked "$crate"
  fi
done < <(bootstrap::packages cargo)
