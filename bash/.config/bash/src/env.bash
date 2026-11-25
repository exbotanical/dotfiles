init::export_builtin PAGER less
init::export LESS '-R'

init::append_path $ExecDir

init::export PATH

init::export SYSTEM_THEME 'ghost'

# i3 starts from the tty login shell through startx, outside the systemd user manager, so it never
# receives the SSH_AUTH_SOCK that gcr-ssh-agent.socket gives that manager. The agent there serves
# the keys whose passphrases the login keyring stores. init::export keeps a socket that GDM or an
# ssh login already set.
[[ -S ${XDG_RUNTIME_DIR:-}/gcr/ssh ]] && init::export SSH_AUTH_SOCK $XDG_RUNTIME_DIR/gcr/ssh
