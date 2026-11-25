# Installs yay from the AUR, then the AUR package lists. makepkg refuses to run as root, so this
# builds as the invoking user and lets makepkg call sudo for the install.

module::applies () {
  [[ $DISTRO == arch ]]
}

module::install () {
  if ! has yay; then
    sudo pacman -S --needed --noconfirm git base-devel
    build_dir=$(mktemp -d)
    trap 'rm -rf "$build_dir"' EXIT
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir"
    (cd "$build_dir" && makepkg -si --noconfirm)
  fi

  local -a packages
  mapfile -t packages < <(bootstrap::packages aur)
  if ((${#packages[@]} == 0)); then
    log '[=] no AUR packages listed'
    return 0
  fi
  yay -S --needed --noconfirm --answerclean None --answerdiff None --removemake "${packages[@]}"
}

# yay -Syu upgrades yay and the AUR packages.
module::outdated () {
  :
}
