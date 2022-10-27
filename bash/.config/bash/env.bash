### Program Paths {{{
export PAGER='less'

# Shpec
export SHPEC_PATH=/usr/local/etc/shpec/bin

# X11
export XDG_CONFIG_HOME="$HOME/.config"

# golang
export GOPATH=$HOME/go

# Java
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export M2_HOME=/usr/local/apache-maven/apache-maven-3.8.6
export M2=$M2_HOME/bin
export MAVEN_OPTS='-Xms256m -Xmx512m'
export PATH=$M2:$PATH

# NVM
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# PNPM
export PNPM_HOME="$HOME/.local/share/pnpm"

# NPM - migrate modules via `nvm install node --reinstall-packages-from=<prev>`
export NODE_PATH="$NODE_PATH:$(npm root -g)"
### End App Paths ### }}}

### Path {{{
export PATH="$PATH:$HOME/.local/bin:$GOPATH/bin:$SHPEC_PATH:$JAVA_HOME:$PNPM_HOME"
### End Path ### }}}
