GIT_COMPLETIONS_FILE="$HOME/.git-completion.bash"

EphemeralVars+=( GIT_COMPLETIONS_FILE )
[[ -f "$GIT_COMPLETIONS_FILE" ]] && {
  . "$GIT_COMPLETIONS_FILE"
}
