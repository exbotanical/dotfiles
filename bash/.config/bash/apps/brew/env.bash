# Escape hatch for osx - system adds homebrew to the PATH prior to bash init.
# Forcibly remove it and prepend it to the PATH.
# Otherwise, the shell env will prefer system defaults over homebrew, which we want.
export PATH="/opt/homebrew/bin:$(echo $PATH | sed 's/\:\/opt\/homebrew\/bin//g')"

init::export BASH_COMPLETION_COMPAT_DIR "$(brew --prefix)/etc/bash_completion.d"
