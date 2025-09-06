#!/usr/bin/env bash
IFS=$'\n'
set -o noglob

INIT_DIR=$HOME/.config/bash

main () {
  mkdir -p ~/.cache/vim
  ln -sf $INIT_DIR/init.bash $HOME/.bashrc
  ln -sf $INIT_DIR/init.bash $HOME/.bash_profile

  echo "[+] Sym-linked bash init file"
}

return 2>/dev/null
set -eu

main
