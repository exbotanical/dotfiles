# pacman_overwrite overwrites an existing package and
# resolves the 'exists in filesystem' error w/ pacman
pacman_overwrite () {
  local pkg="$1"
  sudo pacman -S "$pkg" --overwrite "*"
}
