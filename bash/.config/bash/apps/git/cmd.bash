# gtrack sets the current branch to track its remote counterpart
gtrack () {
  local remote="$1"

  git branch -u "${remote:-origin}/$(git rev-parse --abbrev-ref HEAD)"
}

# gm checkouts the HEAD branch and pulls its latest changes
gm () {
  local default_head='master'
  local head_branch
  head_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo $default_head)"

  git checkout "$head_branch" && git pull origin "$head_branch"
}

# grm_all_but removes all branches in the current repository except
# those provided as a space-delimited list
grm_all_but () {
  local raw="$*"
  local branches_to_ignore="${raw// /|}"
  git branch | grep -vE "$branches_to_ignore" | xargs git branch -D
}
