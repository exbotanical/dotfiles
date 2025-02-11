# Colorization
if ( init::feature_enabled? UseRipgrep ); then
  init::debug 'UseRipgrep enabled'
  Grep='rg'
  GrepRegExpr='rg -e'
  GrepFileExpr='rg -f'
else
  Grep='grep'
  GrepRegExpr='grep -E'
  GrepFileExpr='grep -F'
fi

alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep="$Grep --color=auto"
alias fgrep="$GrepFileExpr --color=auto"
alias egrep="$GrepRegExpr --color=auto"

# ls
if ( init::feature_enabled? UseLsd ); then
  init::debug 'UseLsd enabled'
  LsCommand=lsd
else
  LsCommand=ls
fi

alias ls="$LsCommand --color=auto"
alias ll="$LsCommand -alF"
alias la="$LsCommand -A"
alias l="$LsCommand"

# Safe move
alias mvs='mv -vn'

# Navigation
alias repos='cd ~/repositories'
alias docs='cd ~/Documents'
alias desktop='cd ~/Desktop'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# Purge bash history
alias purgehist='cat /dev/null >| ~/.bash_history'
# Search bash history
alias hs='history | grep'

# Notify for long-running commands
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Perms helpers
alias mx='chmod a+x'
alias ux='chmod u+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# Time
alias now='date +%r'

# Systemd
alias start='sudo systemctl start'
alias restart='sudo systemctl restart'
alias stop='sudo systemctl stop'
alias enable='sudo systemctl enable'
alias disable='sudo systemctl disable'

# reload force-reloads all bash configurations
alias reload="source $RootDir/init.bash reload"

# Open dotfiles to edit
alias dotfiles='code ~/dotfiles'

# Re-open Eww bar until I get around to figuring out why it periodically crashes and/or open an issue
alias bar='eww open bar'
alias schedule='code ~/Documents/studies/schedule.md'

# Quick way to reboot network daemon
alias netreboot='sudo systemctl restart NetworkManager'

EphemeralVars+=(
  Grep
  GrepRegExpr
  GrepFileExpr
  LsCommand
)
