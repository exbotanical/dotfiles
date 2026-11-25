# systemctl --user needs the session's user manager, which a headless login may not have.
[[ $PROFILE == desktop ]] && systemctl --user show-environment &> /dev/null
