### Helpers {{{
__prompt_command () {
  local exit_status=$?
  local number=$(history 1)

  number=${number%% *}

  if [ -n "$number" ]; then
    # if the exit status was 127, remove the erroneous command from history
    if [ $exit_status -eq 127 ] && ([ -z $HISTLASTENTRY ] || [ $HISTLASTENTRY -lt $number ]); then
      history -d $number
    else
      HISTLASTENTRY=$number
    fi
  fi
}
### End Helpers ### }}}

### Interactive Mode Settings {{{

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
bind "set completion-ignore-case on"

# Show auto-completion list automatically, without double tab
bind "set show-all-if-ambiguous on"

# Where cd looks for targets
export CDPATH="."

# Prevent duplicate lines; lines space-prepended in hist
export HISTCONTROL="erasedups:ignoreboth"

# Ignore short commands
export HISTIGNORE="&:ls:[bf]g:exit:pwd:clear:history:ps[ \t]*"

export HISTSIZE=10000

HISTFILESIZE=$(bc<<<$HISTSIZE*2)
export HISTFILESIZE

# Use standard ISO 8601 timestamp
# %F -> %Y-%m-%d
# %T -> %H:%M:%S (24-hr fmt)
export HISTTIMEFORMAT='[%F %T] '

# Colorful manpages - TODO: src colors
export LESS_TERMCAP_mb=$(printf '\e[01;31m') # enter blinking mode – red
export LESS_TERMCAP_md=$(printf '\e[01;35m') # enter double-bright mode – bold, magenta
export LESS_TERMCAP_me=$(printf '\e[0m') # turn off all appearance modes (mb, md, so, us)
export LESS_TERMCAP_se=$(printf '\e[0m') # leave standout mode
export LESS_TERMCAP_so=$(printf '\e[01;33m') # enter standout mode – yellow
export LESS_TERMCAP_ue=$(printf '\e[0m') # leave underline mode
export LESS_TERMCAP_us=$(printf '\e[04;36m') # enter underline mode – cyan

export PROMPT_COMMAND="__prompt_command"

# Remap caps -> super
setxkbmap -option caps:super 2>/dev/null

# Reclaim ctrl-s, ctrl-q
stty -ixon -ixoff

# Prettify less
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# File perms
umask 022
### Interactive Mode Settings ### }}}
