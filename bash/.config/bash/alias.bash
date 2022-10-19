### Colorize {{{
alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
### End Colorize ### }}}

### ls Flag Aliases {{{
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
### End ls Flag Aliases ### }}}

### Navigation {{{
alias repos='cd ~/repositories'
alias docs='cd ~/Documents'
alias desktop='cd ~/Desktop'
alias open='xdg-open'

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
### End Navigation ### }}}

### Git {{{
alias gpull='git pull'
alias gpush='git push'
alias ga='git add'
alias gaa='git add .'
alias gs='git status'
alias gunstage='git reset'
alias gstash='git stash'
# prettify log
alias gl='git log --pretty=format:"%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]" --decorate'
# fetch all remotes
alias gfetch='git fetch --all'
# fetch all remotes and track ea.
alias gfetchtrack='git branch -r | grep -v "\->" | while read remote; do git branch --track "${remote#origin/}" "$remote"; done'
# stage all changes and take them to a new branch
alias gswitch='git add . && git switch -c'
# signed commit
alias gc='git commit -S'
alias gbg="git bisect good"
alias gbb="git bisect bad"
# list all branches from least to most recent
alias gh="git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | tac"
# worktrees :)
alias gw='git worktree add worktree'
alias gwl='git worktree list'
alias gwrm='git worktree remove worktree && git worktree prune'
### End Git ### }}}

### Package Management {{{
# quick pacman update alias
alias upgrade='sudo pacman -Syu'
### End Package Management ### }}}

### Miscellaneous {{{
# purge bash history
alias purgehist='cat /dev/null > ~/.bash_history'
# search bash history
alias hs='history | grep'
### End Miscellaneous ### }}}

### Overrides {{{
alias code='codium'
### End Overrides ### }}}
