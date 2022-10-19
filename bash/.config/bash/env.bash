### Program Settings {{{
# Colorful manpages
export LESS_TERMCAP_mb=$(printf '\e[01;31m') # enter blinking mode – red
export LESS_TERMCAP_md=$(printf '\e[01;35m') # enter double-bright mode – bold, magenta
export LESS_TERMCAP_me=$(printf '\e[0m') # turn off all appearance modes (mb, md, so, us)
export LESS_TERMCAP_se=$(printf '\e[0m') # leave standout mode
export LESS_TERMCAP_so=$(printf '\e[01;33m') # enter standout mode – yellow
export LESS_TERMCAP_ue=$(printf '\e[0m') # leave underline mode
export LESS_TERMCAP_us=$(printf '\e[04;36m') # enter underline mode – cyan
### End Program Settings ### }}}

### Program Paths {{{
# shpec
SHPEC_PATH=/usr/local/etc/shpec/bin

# X11
export XDG_CONFIG_HOME="$HOME/.config"

# golang
export GOPATH=$HOME/go

# java
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export M2_HOME=/usr/local/apache-maven/apache-maven-3.8.6
export M2=$M2_HOME/bin
export MAVEN_OPTS="-Xms256m -Xmx512m"
export PATH=$M2:$PATH

# nvm
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/home/goldmund/.local/share/pnpm"

# npm - migrate modules via `nvm install node --reinstall-packages-from=<prev>`
export NODE_PATH="$NODE_PATH:$(npm root -g)"
### End App Paths ### }}}

### Path {{{
export PATH="$PATH:$HOME/.local/bin:/usr/local/go/bin:$GOPATH/bin:$SHPEC_PATH:$JAVA_HOME:$PNPM_HOME"
### End Path ### }}}
