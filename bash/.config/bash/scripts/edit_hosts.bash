#!/usr/bin/env bash
#desc           :add, remove /etc/hosts entries by IP and hostname
#author         :Matthew Zito
#===============================================================================

current_time () {
  echo $(date +'%Y-%m-%dT%H:%M:%S%z')
}

panic () {
  local exit_status=$1

  shift # pop exit status; we don't want to print it

  echo "[-] ERROR ($(current_time)): $*" >&2
  exit $exit_status
}

usage () {
  cat <<EOF
Add or remove a given line from /etc/hosts. Must be run as root.

Usage:
  $0 \$1 \$2 ?\$3
Options:
  add (\$1) Add an entry, \$2, for IP addr ( \$3 OR $DEFAULT_IP)
  rm (\$1 Remove an entry, \$2, for IP addr ( \$3 OR $DEFAULT_IP)

Examples:
  $0 add local-dev.site 127.0.0.1
  $0 rm local-dev.site 127.0.0.1

EOF
  exit 1
}

IFS=$'\n'

ROOT_UID=0
E_NOTROOT=87
E_FILENOTFOUND=2
E_ARGS=88

HOSTS_FILE="/etc/hosts"
DEFAULT_IP="127.0.0.1"
IP=${3:-$DEFAULT_IP}

if [[ ! -e $HOSTS_FILE ]];then
  panic $E_FILENOTFOUND "Hosts file not found"
fi

if [[ ! $UID -eq $ROOT_UID ]]; then
  panic $E_NOTROOT "Must execute as root"
fi

if (( $# < 2 )); then
  panic $E_ARGS "Insufficient arguments"
fi

case "$1" in
  add )
    echo "$IP $2" >> $HOSTS_FILE
    ;;
  rm )
    sed -ie "\|^$IP $2\$|d" $HOSTS_FILE
    ;;
  * )
    usage
    ;;
esac

exit
