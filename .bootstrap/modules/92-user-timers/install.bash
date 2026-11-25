# Enables and starts the user timers in the systemd package, which 90-dotfiles links into
# ~/.config/systemd/user. night.timer runs `night apply`, which needs redshift.
timers=(eww-covers-clean.timer)
has redshift && timers+=(night.timer)

# Reloads the user manager so that it sees unit files 90-dotfiles linked.
systemctl --user daemon-reload

for timer in "${timers[@]}"; do
  if systemctl --user is-enabled --quiet "$timer" && systemctl --user is-active --quiet "$timer"; then
    log "[=] $timer"
    continue
  fi
  systemctl --user enable --now "$timer"
  log "[+] $timer"
done
