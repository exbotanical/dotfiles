# Initializes opam where the package lists install it. --no-setup stops opam from editing shell
# files; apps/opam/env.bash loads its environment instead. Unprivileged containers cannot run
# opam's bubblewrap sandbox, so BOOTSTRAP_CONTAINER disables it.

module::applies () {
  has opam
}

module::install () {
  if [[ -d $HOME/.opam ]]; then
    log "[=] opam $(opam --version)"
    return 0
  fi

  local -a flags=(--no-setup --yes)
  [[ -n ${BOOTSTRAP_CONTAINER:-} ]] && flags+=(--disable-sandboxing)
  opam init "${flags[@]}"
}

# The package lists install opam, and opam upgrade upgrades its packages.
module::outdated () {
  :
}
