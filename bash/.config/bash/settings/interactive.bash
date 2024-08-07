# Prevent file overwrite on stdout redirection
# Use `>|` to force redirection to an existing file
set -o noclobber

# Print job statuses (if extant) when attempting to exit
shopt -s checkjobs

# Send a SIGHUP to jobs on exit
shopt -s huponexit

# Update window size after ea cmd and recalibrate if needed
shopt -s checkwinsize

# Recursive globbing (enables ** to recurse all directories)
shopt -s globstar

# Enable extended pattern-matching features
shopt -s extglob

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Correct spelling errors in arguments supplied to cd
shopt -s cdspell 2> /dev/null

# Correct spelling errors during tab-completion
shopt -s dirspell 2> /dev/null

# Allow vars to be used with cd
shopt -s cdable_vars

# Append to hist; don't overwrite
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Case insensitive file completion
bind 'set completion-ignore-case on'

# Show auto-completion list automatically, without double tab
bind 'set show-all-if-ambiguous on'

# Where cd looks for targets
init::export CDPATH .

# Prevent duplicate lines; lines space-prepended in hist
init::export HISTCONTROL erasedups:ignoreboth

# Ignore short commands
init::export HISTIGNORE '&:ls:[bf]g:exit:pwd:clear:history*'

init::export HISTSIZE 10000
init::export HISTFILESIZE $(bc<<<$HISTSIZE*2)

# Use standard ISO 8601 timestamp
init::export HISTTIMEFORMAT '[%Y-%m-%dT%H:%M:%S] '

# Colorful manpages - TODO: src colors
init::export LESS_TERMCAP_mb $(printf '\e[01;31m') # enter blinking mode – red
init::export LESS_TERMCAP_md $(printf '\e[01;35m') # enter double-bright mode – bold, magenta
init::export LESS_TERMCAP_me $(printf '\e[0m') # turn off all appearance modes (mb, md, so, us)
init::export LESS_TERMCAP_se $(printf '\e[0m') # leave standout mode
init::export LESS_TERMCAP_so $(printf '\e[01;33m') # enter standout mode – yellow
init::export LESS_TERMCAP_ue $(printf '\e[0m') # leave underline mode
init::export LESS_TERMCAP_us $(printf '\e[04;36m') # enter underline mode – cyan

# Reclaim ctrl-s, ctrl-q
stty -ixon -ixoff

# Prettify less
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# GCC color config
init::export GCC_COLORS 'error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# PS2 prompt
init::export PS2 "\[$(tput setaf 3)\]continue--> "

init::export EDITOR $(command -v vim 2>/dev/null || command -v vi)

# File perms
umask 022

# Remap caps -> super
init::feature_enabled? REMAPCAPSTOSUPER && {
  init::debug 'REMAPCAPSTOSUPER enabled; remapping caps lock key to super'
  setxkbmap -option caps:super 2>/dev/null
}
