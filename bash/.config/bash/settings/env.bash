init::export_builtin PAGER less

# X
init::export XDG_CONFIG_HOME $HOME/.config

# Go
init::export GOPATH $HOME/go
init::append_path $GOPATH/bin

# Java
init::export JAVA_HOME /usr/lib/jvm/java-17-openjdk-amd64
init::export M2_HOME /usr/local/apache-maven/apache-maven-3.8.6
init::export M2 $M2_HOME/bin
init::export MAVEN_OPTS '-Xms256m -Xmx512m'

init::append_path $JAVA_HOME
init::append_path $M2

# NVM
init::export NVM_DIR $HOME/.config/nvm
# Load NVM
[ -s "$NVM_DIR/nvm.sh" ] && source $NVM_DIR/nvm.sh

# Load NVM completions
[ -s "$NVM_DIR/bash_completion" ] && source $NVM_DIR/bash_completion

# PNPM
init::export PNPM_HOME $HOME/.local/share/pnpm
init::append_path $PNPM_HOME

# NPM - migrate modules via `nvm install node --reinstall-packages-from=<prev>`
init::export NODE_PATH $(npm root -g)

init::append_path $ExecDir

init::export PATH
