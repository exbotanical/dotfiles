BASH_COMPLETIONS_FILE="$(brew --prefix)/etc/profile.d/bash_completion.sh"
EphemeralVars+=( BASH_COMPLETIONS_FILE )
[[ -f "$BASH_COMPLETIONS_FILE" ]] && {
  . "$BASH_COMPLETIONS_FILE"
}
