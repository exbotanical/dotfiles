GIT_COMPLETIONS_FILE='/usr/share/bash-completion/completions/git'

EphemeralVars+=( GIT_COMPLETIONS_FILE )
[[ -f "$GIT_COMPLETIONS_FILE" ]] && {
  . "$GIT_COMPLETIONS_FILE"
}
