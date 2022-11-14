#!/usr/bin/env bash
#desc           :enables port forwarding
#author         :Matthew Zito
#===============================================================================

main () {
  read -pr "[*] Warning: this script will modify your IP Tables configurations. Continue? (y/n) " answer

  case $answer in
    y )
      if [[ ! -x $TABLES_F ]]; then
        echo "[-] \"${TABLES_F}\" not found.";
        exit "$E_FILENOTFOUND";
      fi

      echo "[+] Updating rules..."
      echo 1 > /proc/sys/net/ipv4/ip_forward
      # clear rules that potentially interfere with port forwarding
      iptables --flush
      iptables --table nat --flush
      iptables --delete-chain
      iptables --table nat --delete-chain
      iptables -P FORWARD_ACCEPT
      echo "[+] Port forwarding enabled."
      ;;
    n )
      exit 0
      ;;
    * )
      main
      ;;
  esac
}

ROOT_UID=0
E_FILENOTFOUND=2
E_NOTROOT=87

TABLES_F="/sbin/iptables"

# stop here if being sourced
return 2>/dev/null

set -o errexit

if [[ $EUID -ne $ROOT_UID ]]; then
  echo "[-] This script should be run as root.";
  exit $E_NOTROOT;
fi

main
