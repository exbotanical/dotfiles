# Colorization
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ls
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Navigation
alias repos='cd ~/repositories'
alias docs='cd ~/Documents'
alias desktop='cd ~/Desktop'
alias open='xdg-open'

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
alias reload='source ~/.config/bash/init.bash reload'

# Open dotfiles to edit
alias dotfiles='code ~/dotfiles'

# Re-open Eww bar until I get around to figuring out why it periodically crashes and/or open an issue
alias bar='eww open bar'
