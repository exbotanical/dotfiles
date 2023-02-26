#!/usr/bin/env bash

EXTENSIONS=($(vscodium --list-extensions --show-versions))

for extension in "${EXTENSIONS[@]}";do
  vscodium --install-extension "$extension"
done
