# Prints the name of the machine profile we should load from directory $1.
# Selects $2 when $1/$2.env exists, otherwise selects the profile that sets DEFAULT=1.
# When the number of profiles that set DEFAULT=1 is not exactly one, the lexicographically prior candidate wins.
# Sourced by .xprofile and the bootstrap target's entry script; fallbacks are reported to stderr.
machines_select () {
  local dir=$1 name=$2 file profile
  local -a profiles=() defaults=()

  # 1. The selected name wins when a profile file of that name exists.
  if [[ -n $name && -f $dir/$name.env ]]; then
    printf '%s\n' "$name"
    return 0
  fi

  # 2. Every step hereafter is a fallback.
  # In each, we print to stderr the reason why we're using the fallback in lieu of the given selection (if any).
  if [[ -z $name ]]; then
    printf 'machines: no machine selected in ~/.config/machine\n' >&2
  else
    printf 'machines: no profile %s.env in %s\n' "$name" "$dir" >&2
  fi

  # 3. Collect every profile name and, separately, those which set DEFAULT=1.
  # The glob expands in alphabetical order, so index 0 of each array is the first
  # (i.e. the lexicographical prior; viz., the candidate).
  for file in "$dir"/*.env; do
    [[ -f $file ]] || continue

    profile=${file##*/}     # strip the directory
    profile=${profile%.env} # strip the extension
    profiles+=("$profile")  # append

    if grep -q '^DEFAULT=1$' "$file"; then
      defaults+=("$profile")
    fi
  done

  # 4. Select exactly one default.
  # Zero profiles is erroneous.
  # Non-singular default means we fallback to the lexicographically prior candidate, as aforementioned.
  if ((${#profiles[@]} == 0)); then
    printf 'machines: no profiles in %s\n' "$dir" >&2
    return 1
  elif ((${#defaults[@]} == 0)); then
    printf 'machines: no profile sets DEFAULT=1; using %s\n' "${profiles[0]}" >&2
    defaults=("${profiles[0]}")
  elif ((${#defaults[@]} > 1)); then
    printf 'machines: %s profiles set DEFAULT=1; using %s\n' "${#defaults[@]}" "${defaults[0]}" >&2
  else
    printf 'machines: using default profile %s\n' "${defaults[0]}" >&2
  fi

  printf '%s\n' "${defaults[0]}"
}
