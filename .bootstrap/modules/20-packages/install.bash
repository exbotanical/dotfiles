# Installs the native package lists for the distro. Each manager skips installed packages.
mapfile -t packages < <(
  case $DISTRO in
    arch) bootstrap::packages pacman ;;
    ubuntu) bootstrap::packages apt ;;
    al2023) bootstrap::packages dnf ;;
  esac
)
if ((${#packages[@]} == 0)); then
  log "[=] no $DISTRO packages listed"
  exit 0
fi

case $DISTRO in
  arch) sudo pacman -Syu --needed --noconfirm "${packages[@]}" ;;
  ubuntu)
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
    ;;
  al2023) sudo dnf install -y "${packages[@]}" ;;
esac
