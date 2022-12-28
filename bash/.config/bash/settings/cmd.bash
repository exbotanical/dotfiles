# extract unarchives the file based on the archive type
extract () {
  local file_name="$1"

  echo Extracting "$file_name"...

  if [[ -f $file_name ]]; then
    case $file_name in
      *.tar.bz2)  tar xjf "$file_name"      ;;
      *.tar.gz)   tar xzf "$file_name"      ;;
      *.bz2)      bunzip2 "$file_name"      ;;
      *.rar)      rar x "$file_name"        ;;
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

# mk_alias adds new aliases
# mk_alias name "val"
mk_alias () {
  local alias_name="$1"

  shift

  local alias_body="$*"

  [[ -z "$alias_name" ]] && {
    echo "[-] Alias name not provided"
    return 1
  }

  [[ -z "$alias_body" ]] && {
    echo "[-] Alias body not provided"
    return 1
  }

  echo "alias $alias_name='$alias_body'" >> "$BASH_CONFIG/alias.bash"

  (( "$?" == 0 )) && echo "[+] Successfully added new alias"
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

# webcam links external webcam to default
webcam () {
  DEFAULT_WEBCAM='video0'
  EXTERNAL_WEBCAM='video2'

  sudo unlink /dev/$EXTERNAL_WEBCAM
  sudo ln -s /dev/$DEFAULT_WEBCAM /dev/$EXTERNAL_WEBCAM
}

# lsuptime prints the system uptime
lsuptime () {
  uptime | awk '{ print "Uptime:", $3, $4, $5 }' | sed 's/,//g'
}

# lscmd prints the most used commands
lscmd () {
  history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n10
}

# toggle_k toggles the keyboard layout between qwerty and programmer dvorak
toggle_k () {
  local current_variant=$(setxkbmap -query | grep "variant")
  [[ "$current_variant" == '' ]] && setxkbmap -variant dvp || setxkbmap us
}

# mon_3 switches to a tri-monitor layout
mon_3 () {
  xrandr --output eDP-1 --primary --mode 2256x1504 --pos 0x416 --rotate normal \
  --output DP-1 --mode 3840x2160 --pos 3336x0 --rotate normal                  \
  --output DP-2 --mode 1920x1080 --pos 2256x0 --rotate left                    \
  --output DP-3 --off --output DP-4 --off
}

# mon_default resets the display configurations to the defaults
mon_default () {
  xrandr -s 0
}
