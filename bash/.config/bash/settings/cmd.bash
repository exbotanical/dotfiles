# extract unarchives the file based on the archive type
extract () {
  local file_name="$1"

  echo Extracting "$file_name"...

  if [[ -f $file_name ]]; then
    case $file_name in
      *.tar.bz2)  tar xjf "$file_name"      ;;
      *.tar.gz)   tar xzf "$file_name"      ;;
      *.bz2)      bunzip2 "$file_name"      ;;
      *.rar)      unrar x "$file_name"      ;;
      *.gz)       gunzip "$file_name"       ;;
      *.tar)      tar xf "$file_name"       ;;
      *.tbz2)     tar xjf "$file_name"      ;;
      *.tgz)      tar xzf "$file_name"      ;;
      *.zip)      unzip "$file_name"        ;;
      *.Z)        uncompress "$file_name"   ;;
      *.7z)       7z x "$file_name"         ;;
      *.xz)       xz -d "$file_name"        ;;
      *)          echo "'$file_name' cannot be extracted via extract" ;;
    esac
  else
    echo "'$file_name' is not a valid file"
  fi
}

# bak backs up a file with a timestamp in the name
bak () {
  local file_name="$1"
  cp "$file_name" "${file_name}-$(date +%Y%m%d%H%M).bak"
}

# ptree displays tree of running user processes
ptree () {
  ps f -u "$USER" -o command,pid,%cpu,%mem,time,etime,tty | \
    awk 'NR <= 1 {print;next} !/awk/ && $0~var' var="${1:-".*"}"
}

# psaux less-es running processes of the given target
psaux () {
  pgrep -f "$@" | xargs ps -fp 2>/dev/null
}

# open_enc mounts an encrypted directory
open_enc () {
  local mount="$1"
  local proxy="$2"

  encfs "${mount:-$HOME/.enc/}" "${proxy:-$HOME/enc/}"
}

# close_enc unmounts an encrypted directory
close_enc () {
  local proxy="$1"

  fusermount -u "${proxy:-$HOME/enc}"
}

# cheat searches cheat.sh
cheat () {
  curl "cht.sh/$*"
}

# lsuptime prints the system uptime
lsuptime () {
  uptime | awk '{ print "Uptime:", $3, $4, $5 }' | sed 's/,//g'
}

# lscmd prints the most used commands
lscmd () {
  history | awk '{CMD[$4]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n10
}

# toggle_k toggles the keyboard layout between qwerty and programmer dvorak
toggle_k () {
  local current_variant=$(setxkbmap -query | grep "variant")
  [[ "$current_variant" == '' ]] && setxkbmap -variant dvp || setxkbmap us
}

# cmd_out runs a command and pipes its stdout and stderr to respective files
cmd_out () {
  local cmd="$*"
  $cmd >| stdout.txt 2>| stderr.txt
}

# cmd_out_clean quietly tries to remove the cmd_out artifacts
cmd_out_clean () {
  rm stdout.txt stderr.txt &>/dev/null
}

# ssh_cache starts the ssh agent and caches the private key
# this allows the user to avoid entering the passphrase over and over
ssh_cache () {
  local SSH_KPATH="$HOME/.ssh/id_rsa"

  eval $(ssh-agent -s)
  ssh-add "$SSH_KPATH"
}
