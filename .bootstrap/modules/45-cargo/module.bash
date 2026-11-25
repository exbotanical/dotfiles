# Installs the cargo package lists with the rustup toolchain.

module::applies () {
  [[ -n $(bootstrap::packages cargo) ]]
}

module::install () {
  local installed crate
  installed=$(cargo install --list)
  while IFS= read -r crate; do
    if [[ $installed == *$'\n'"$crate "* || $installed == "$crate "* ]]; then
      log "[=] $crate"
    else
      cargo install --locked "$crate"
    fi
  done < <(bootstrap::packages cargo)
}

# The cargo lists name no versions, so there is no pin to compare.
module::outdated () {
  :
}
