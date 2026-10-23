# Installs yay from the AUR, then the AUR package lists. makepkg refuses to run as root, so this
# builds as the invoking user and lets makepkg call sudo for the install.
if ! has yay; then
  sudo pacman -S --needed --noconfirm git base-devel
  build_dir=$(mktemp -d)
  trap 'rm -rf "$build_dir"' EXIT
  git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir"
  (cd "$build_dir" && makepkg -si --noconfirm)
fi

mapfile -t packages < <(bootstrap::packages aur)
if ((${#packages[@]} == 0)); then
  log '[=] no AUR packages listed'
  exit 0
fi
yay -S --needed --noconfirm --answerclean None --answerdiff None --removemake "${packages[@]}"
