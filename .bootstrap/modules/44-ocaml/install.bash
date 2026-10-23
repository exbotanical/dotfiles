# Initializes opam where the package lists install it. --no-setup stops opam from editing shell
# files; apps/opam/env.bash loads its environment instead. Unprivileged containers cannot run
# opam's bubblewrap sandbox, so BOOTSTRAP_CONTAINER disables it.
if [[ -d $HOME/.opam ]]; then
  log "[=] opam $(opam --version)"
  exit 0
fi

flags=(--no-setup --yes)
[[ -n ${BOOTSTRAP_CONTAINER:-} ]] && flags+=(--disable-sandboxing)
opam init "${flags[@]}"
