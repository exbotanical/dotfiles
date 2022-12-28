init::export_builtin PAGER less

# X
init::export XDG_CONFIG_HOME $HOME/.config

# Go
init::append_path /usr/local/go/bin

init::append_path $ExecDir

init::export PATH
