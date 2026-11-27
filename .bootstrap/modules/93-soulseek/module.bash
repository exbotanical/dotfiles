# Prepares the Soulseek setup: its folders, and ClamAV signatures for the batch scan.
# clamav-freshclam-once.timer, which the clamav package ships, runs freshclam daily and catches up
# after a missed day.
readonly FOLDERS=(
  "$HOME/Downloads/soulseek/incomplete"
  "$HOME/Downloads/soulseek/received"
  "$HOME/Downloads/soulseek-quarantine"
  "$HOME/.local/share/beets/review"
)
readonly SIGNATURES_DIR=/var/lib/clamav
readonly FRESHCLAM_TIMER=clamav-freshclam-once.timer

module::applies () {
  [[ $DISTRO == arch ]] && has nicotine && has freshclam
}

module::install () {
  mkdir -p "${FOLDERS[@]}"
  log '[=] soulseek folders'

  if systemctl is-enabled --quiet "$FRESHCLAM_TIMER"; then
    log "[=] $FRESHCLAM_TIMER"
  else
    sudo systemctl enable --now "$FRESHCLAM_TIMER"
    log "[+] $FRESHCLAM_TIMER"
  fi

  if compgen -G "$SIGNATURES_DIR/main.c[lv]d" > /dev/null; then
    log '[=] ClamAV signatures'
  else
    sudo freshclam
  fi
}

# pacman upgrades the packages, and the timer the signatures.
module::outdated () {
  :
}
