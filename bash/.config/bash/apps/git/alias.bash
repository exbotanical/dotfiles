### I prefer defining my Git aliases in bash over gitconfig
alias gpull='git pull'
alias gpush='git push'
alias ga='git add'
# Git add all
alias gaa='git add .'
alias gs='git status'
alias gunstage='git reset'
alias gstash='git stash'
# Fetch all remotes
alias gfetch='git fetch --all'
# Fetch all remotes and track each
# shellcheck disable=SC2154
alias gfetchtrack='git branch -r | grep -v "\->" | while read remote; do git branch --track "${remote#origin/}" "$remote"; done'
# Stage all changes and take them to a new branch
alias gswitch='git add . && git switch -c'
alias gc='git commit'
# Amend commit with no message change
alias gca='git commit --amend --no-edit'
alias gbg="git bisect good"
alias gbb="git bisect bad"
# List all branches from least to most recent
alias gh="git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | tac"
### Worktrees :)
alias gw='git worktree add worktree'
alias gwl='git worktree list'
alias gwrm='git worktree remove worktree && git worktree prune'
### Metadata and Informational
alias gauthors='git shortlog --summary --numbered --email'
# Prettify log
alias gl='git log --pretty=format:"%C(magenta)%h%Cgreen%d %Creset%s%C(cyan) [%cn]" --decorate'
alias gl1='gl -n1'
alias gl2='gl -n2'
alias gl3='gl -n3'
