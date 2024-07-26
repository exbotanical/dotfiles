#!/usr/bin/env bash

# TODO:
EXTENSIONS=($(vscodium --list-extensions --show-versions))

for extension in "${EXTENSIONS[@]}";do
  vscodium --install-extension "$extension"
done
