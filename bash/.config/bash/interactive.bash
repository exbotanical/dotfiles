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

# prevent duplicate lines; lines space-prepended in hist
HISTCONTROL=ignoreboth

# append to hist; don't overwrite
shopt -s histappend

# set hist len
HISTSIZE=1000
HISTFILESIZE=2000

# ignore short commands
HISTIGNORE="&:ls:[bf]g:exit:pwd:clear:[ \t]*"

# eval window size after ea cmd and recalibrate if needed
shopt -s checkwinsize

shopt -s globstar

# prettify less
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"


# bash completion on
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# file perms
umask 022
### Interactive Mode Settings ### }}}
