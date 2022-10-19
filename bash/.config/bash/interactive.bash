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

PROMPT_COMMAND="__prompt_command"

# Prevent file overwrite on stdout redirection
# Use `>|` to force redirection to an existing file
set -o noclobber

# Update window size after ea cmd and recalibrate if needed
shopt -s checkwinsize

# Recursive globbing (enables ** to recurse all directories)
shopt -s globstar 2> /dev/null

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Correct spelling errors in arguments supplied to cd
shopt -s cdspell 2> /dev/null

# Correct spelling errors during tab-completion
shopt -s dirspell 2> /dev/null

# Enable CDPATH
shopt -s cdable_vars
# Where cd looks for targets
CDPATH="."

# Append to hist; don't overwrite
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Prevent duplicate lines; lines space-prepended in hist
HISTCONTROL="erasedups:ignoreboth"

# Ignore short commands
export HISTIGNORE="&:ls:[bf]g:exit:pwd:clear:history:ps[ \t]*"

HISTSIZE=1000
HISTFILESIZE=2000

# Use standard ISO 8601 timestamp
# %F -> %Y-%m-%d
# %T -> %H:%M:%S (24-hr fmt)
HISTTIMEFORMAT='%F %T '

# Remap caps -> super
setxkbmap -option caps:super 2>/dev/null

# Case insensitive file completion
bind "set completion-ignore-case on"

# Prettify less
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# File perms
umask 022
### Interactive Mode Settings ### }}}
