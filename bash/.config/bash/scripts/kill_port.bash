#!/usr/bin/env bash
#desc           :Kill process running on given port.
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

get_pid () {
  local target_port=$1

  lsof -ni :$target_port 2>/dev/null | grep LISTEN | awk '{ print $2 }'
}

main () {
  local port=$1

  [[ ${#port} -lt 4 || ${#port} -gt 5 ]] && {
    panic $E_BADARG "Invalid port number: $port"
  }

  pid=$(get_pid $port)

  [[ -z "$pid" ]] && {
    echo "[*] Port not in use"
    exit 0
  }

  kill -9 $pid 2>/dev/null && echo "[+] Process terminated"

  exit
}

IFS=$'\n'

E_ARGS=88
E_BADARG=89

[[ -z "$1" ]] && panic $E_ARGS "A parameter is required"

main $1
