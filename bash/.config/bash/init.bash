# shellcheck disable=SC1091

BASH_CONFIG="$HOME/.config/bash"

### Environment ### {{{
source "$BASH_CONFIG/env.bash"
### End Environment ### }}}

### Commands ### {{{
source "$BASH_CONFIG/cmd.bash"
### End Commands ### }}}

### Aliases ### {{{
source "$BASH_CONFIG/alias.bash"
### End Aliases ### }}}

### Interactive ### {{{
if [[ $- == *i* ]]; then
  source "$BASH_CONFIG/interactive.bash"
  source "$BASH_CONFIG/login.bash"
fi
### End Interactive ### }}}

### GUI {{{
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
	exec startx
fi
### End GUI }}}
