### Helpers {{{
# if the exit status was 127, remove the erroneous command from history
__prompt_command () {
  local exit_status=$?
  local number=$(history 1)

  number=${number%% *}

  if [ -n "$number" ]; then
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

# append to hist; don't overwrite
shopt -s histappend

# prevent duplicate lines; lines space-prepended in hist
HISTCONTROL=ignorespace:erasedups
HISTSIZE=1000
HISTFILESIZE=2000
# ignore short commands
HISTIGNORE="&:ls:[bf]g:exit:pwd:clear:history:ps[ \t]*"

# eval window size after ea cmd and recalibrate if needed
shopt -s checkwinsize

shopt -s globstar

# prettify less
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# file perms
umask 022
### Interactive Mode Settings ### }}}
