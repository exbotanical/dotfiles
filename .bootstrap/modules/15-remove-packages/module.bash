# Removes the packages in the remove lists that are installed, before 20-packages and 30-aur
# install their replacements. A replacement can conflict with the package it replaces, as eww-git
# does with eww, and yay --noconfirm declines to remove a conflicting package. On Ubuntu, a package
# that is removed but keeps its configuration files (dpkg status rc) is purged.

module::applies () {
  [[ $DISTRO == arch || $DISTRO == ubuntu ]]
}

module::install () {
  local -a listed packages
  mapfile -t listed < <(bootstrap::packages remove)
  mapfile -t packages < <("installed_$DISTRO" "${listed[@]}")
  if ((${#packages[@]} == 0)); then
    log '[=] no listed package to remove'
    return 0
  fi

  log "[-] removing ${packages[*]}"
  case $DISTRO in
    arch) sudo pacman -R --noconfirm "${packages[@]}" ;;
    ubuntu) sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y "${packages[@]}" ;;
  esac
}

module::outdated () {
  :
}

# Prints the listed packages that are installed. pacman -Qq prints the installed name, which
# differs from the listed one when another package only provides it.
installed_arch () {
  local package
  for package; do
    [[ $(pacman -Qq "$package" 2> /dev/null) == "$package" ]] && printf '%s\n' "$package"
  done
  return 0
}

installed_ubuntu () {
  local package status
  for package; do
    status=$(dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2> /dev/null || true)
    [[ $status == ii* || $status == rc* ]] && printf '%s\n' "$package"
  done
  return 0
}
