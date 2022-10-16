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

# npm
export NODE_PATH="$NODE_PATH:$(npm root -g)"
# migrate modules via `nvm install node --reinstall-packages-from=<prev>`

### Path {{{
export PATH="$PATH:$HOME/.local/bin:/usr/local/go/bin:$GOPATH/bin:$SHPEC_PATH:$JAVA_HOME:$PNPM_HOME"
### End Path ### }}}
