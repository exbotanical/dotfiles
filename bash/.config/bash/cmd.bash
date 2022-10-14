### Extract - Unzip anything ### {{{
# src: http://nparikh.org/notes/zshrc.txt
extract () {
  echo Extracting $1 ...
  if [[ -f $1 ]]; then
    case $1 in
      *.tar.bz2)  tar xjf $1      ;;
      *.tar.gz)   tar xzf $1      ;;
      *.bz2)      bunzip2 $1      ;;
      *.rar)      rar x $1        ;;
      *.gz)       gunzip $1       ;;
      *.tar)      tar xf $1       ;;
      *.tbz2)     tar xjf $1      ;;
      *.tgz)      tar xzf $1      ;;
      *.zip)      unzip $1        ;;
      *.Z)        uncompress $1   ;;
      *.7z)       7z x $1         ;;
      *.xz)       xz -d $1        ;;
      *)          echo "'$1' cannot be extracted via `extract`" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
### End Extract ### }}}

### Base64 ### {{{
base64 () {
  while getopts ":d:e:" opt; do
    case $opt in
      d)
        echo $OPTARG | openssl enc -d -base64
        ;;
      e)
        openssl base64<<<"$OPTARG"
        ;;
      \?)
        echo "[-] Invalid option: -$OPTARG" >&2
        ;;
      :)
        echo "[!] Option -$OPTARG requires an argument" >&2
        ;;
    esac
  done

  # reset because we're probably going to be in the same shell for a while
  OPTIND=1
}
### End Base64 ### }}}

### RMD - Render a Markdown File ### {{{
rmd () {
  pandoc "$1" | lynx -stdin
}
### End RMD ### }}}

### Mk_alias - Add a New Alias ### {{{
# mk_alias name "val"
mk_alias () {
  local alias_name="$1"

  shift

  local alias_body="$@"

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
### End Mk_alias ### }}}

### Psaux - Less Running Processes of Target ### {{{
psaux () {
  pgrep -f "$@" | xargs ps -fp 2>/dev/null
}
### End Psaux ### }}}

### open_enc - Mount Encrypted Directories {{{
open_enc () {
  local mount="$1" proxy="$2"

  encfs ${mount:-~/.enc/} ${proxy:-~/enc/}
}
### End open_enc ### }}}

### close_enc - Unmount Encrypted Directories {{{
close_enc () {
  local proxy="$1"

  fusermount -u ${proxy:-~/enc}
}
### End close_enc ### }}}

### Connect Bluetooth Device Connection {{{
blue_conn () {
  local default='28:F0:33:D0:61:14'

  # must have edited config rules
  bluetoothctl connect "${1:-$default}"
}
### End Bluetooth Device Connection ### }}}

### Dockerize - Launch a Containerized Dev Env of PWD {{{
dockerize () {
  docker_image='ghcr.io/exbotanical/docker-dev-env:latest'

  echo -e "Building a fresh dev environment as an ephemeral container in $(pwd)...\n"
  docker run --rm -it -v "$(pwd):/ephemeral" "ghcr.io/exbotanical/docker-dev-env:latest"
}
### End Dockerize ### }}}

### Bootstrap - Initialize a New Project of Type $1 {{{
bootstrap () {
  local script_loc="$BASH_CONFIG/scripts/bootstrap.bash"

  if (( $# != 2 )); then
    echo -e "[!] No arguments supplied\n"
  else
    bash $script_loc "$1" "$2"
  fi
}
### End Bootstrap ### }}}

### Git {{{

# Set Current Branch to Track Remote (default: 'origin')
gtrack () {
  local remote="$1"

  git branch -u "${remote:-origin}/$(git rev-parse --abbrev-ref HEAD)"
}

# Checkout HEAD branch and pull latest
gm () {
  local default_head='master'
  local head="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo $default_head)"

  git checkout $head && git pull origin $head
}
### End Git ### }}}

### Cheat - cheat.sh {{{
cheat () {
  curl cht.sh/$*
}
### End Cheat ### }}}

### Webcam Ctrl {{{
# Link external webcam to default.
webcam () {
  DEFAULT_WEBCAM='video0'
  EXTERNAL_WEBCAM='video2'

  sudo unlink /dev/$EXTERNAL_WEBCAM
  sudo ln -s /dev/$DEFAULT_WEBCAM /dev/$EXTERNAL_WEBCAM
}
### End Webcam Ctrl ### }}}

### Monitor Ctrl {{{
mon () {
  local mode="$1"

  if [[ -z "$mode" ]]; then
    echo "[-] No argument supplied."
    exit 1
  fi

  local dir="$HOME/config/.screenlayout"

  case $mode in
    1)
      "$dir/singlescreen.sh"
      ;;
    2)
      "$dir/dualscreen.sh"
      ;;
    3)
      "$dir/triscreen.sh"
      ;;
    4)
      "$dir/quadscreen.sh"
      ;;
    *)
      echo "[-] '$mode' is not a valid option"
      exit 1
      ;;
  esac
}

darken () {
  local percentage="${1:-.7}"
  local default_output="eDP-1"

  xrandr --output $default_output --brightness $percentage
}
### End Monitor Ctrl ### }}}
