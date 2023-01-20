#!/usr/bin/env bash
#desc           :add, remove /etc/hosts entries by IP and hostname
#author         :Matthew Zito
#===============================================================================
# shellcheck disable=SC2086,SC2048

current_time () {
  date +'%Y-%m-%dT%H:%M:%S%z'
}

panic () {
  local exit_status=$1; shift

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
}

validate_hosts_file () {
  [[ ! -e $HOSTS_FILE ]] && {
    panic $E_FILENOTFOUND "Hosts file not found"
  }
}

validate_root_user () {
  [[ ! $UID -eq $ROOT_UID ]] && {
    panic $E_NOTROOT "Must execute as root"
  }
}

validate_args () {
  local n_expected_args=$1
  local n_args=$2

  (( n_args < n_expected_args )) && {
    panic $E_ARGS "Insufficient arguments"
  }
}

IFS=$'\n'

ROOT_UID=0
E_NOTROOT=87
E_FILENOTFOUND=2
E_ARGS=88

HOSTS_FILE="/etc/hosts"
DEFAULT_IP="127.0.0.1"
IP=${3:-$DEFAULT_IP}

validate_args 1 $#

case "$1" in
  add )
    validate_args 2 $#
    validate_hosts_file
    validate_root_user

    echo -e "$IP\t$2" >> $HOSTS_FILE
    ;;
  rm )
    validate_args 2 $#
    validate_hosts_file
    validate_root_user

    sed -ie "\|^$IP $2\$|d" $HOSTS_FILE
    ;;
  help | --help )
    usage
    exit 0
    ;;
  * )
    echo "Unknown argument $1"
    exit $E_ARGS
    ;;
esac
