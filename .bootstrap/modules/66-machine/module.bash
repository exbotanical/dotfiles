# Writes this machine's profile name to ~/.config/machine,
# from which ~/.xprofile loads ~/.config/machines/<name>.env.
# MACHINE=<name> selects a profile in x11/.config/machines.
# Without MACHINE, a selection that names an existing profile is used;
# else, the default profile is used (see select.bash for fallback logic).
# If a fallback is selected, the reason will be written to stderr.
readonly MACHINE_FILE=$HOME/.config/machine
readonly MACHINES_DIR=$REPO_DIR/x11/.config/machines

module::applies () {
  [[ $PROFILE == desktop ]]
}

module::install () {
  source "$MACHINES_DIR/select.bash"

  local current name
  current=$(cat "$MACHINE_FILE" 2> /dev/null || true)

  if [[ -n ${MACHINE:-} ]]; then
    [[ -f $MACHINES_DIR/$MACHINE.env ]] || die "[!] no machine profile $MACHINE.env in $MACHINES_DIR"
    name=$MACHINE
  else
    name=$(machines_select "$MACHINES_DIR" "$current")
  fi

  if [[ $current == "$name" ]]; then
    log "[=] machine: $name"
    return 0
  fi

  mkdir -p "${MACHINE_FILE%/*}"
  printf '%s\n' "$name" > "$MACHINE_FILE"
  log "[+] machine: $name"
}

module::outdated () {
  :
}
