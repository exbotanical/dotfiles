# Sourcing nvm.sh also runs nvm_auto, which resolves the default alias to put
# node on PATH. That needs word-splitting (it splits "nvm_ls node" into command
# + arg) and globbing (it passes /* to find) - both of which apps.bash enables
# only around app init.bash, not interactive.bash.

# Load NVM
[ -s "$NVM_DIR/nvm.sh" ] && {
  source $NVM_DIR/nvm.sh
}

# Load NVM completions
[ -s "$NVM_DIR/bash_completion" ] && {
  source $NVM_DIR/bash_completion
}
