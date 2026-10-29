# Installs the GTK, icon, and cursor themes the gtk, x11, and i3 configs name. Neither distro
# packages them under these names. Icons and cursors go to ~/.local/share/icons because the gtk
# package stows ~/.icons.
readonly THEMES_DIR=$HOME/.themes
readonly ICONS_DIR=$HOME/.local/share/icons

# Downloads the zip at $3 and moves its top-level directory $2 to $1, unless $1 exists.
install_theme () {
  local dest=$1 top=$2 url=$3
  local name=${dest#"$HOME"/}

  if [[ -d $dest ]]; then
    log "[=] $name"
    return
  fi

  local work
  work=$(mktemp -d)
  curl -fsSLo "$work/theme.zip" "$url"
  unzip -q "$work/theme.zip" -d "$work"
  mkdir -p "${dest%/*}"
  mv "$work/$top" "$dest"
  rm -rf "$work"
  log "[+] $name"
}

install_theme "$THEMES_DIR/Dracula" gtk-master \
  https://github.com/dracula/gtk/archive/master.zip
install_theme "$ICONS_DIR/Dracula" Dracula \
  https://github.com/dracula/gtk/files/5214870/Dracula.zip
install_theme "$ICONS_DIR/catppuccin-frappe-sapphire-cursors" catppuccin-frappe-sapphire-cursors \
  https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-frappe-sapphire-cursors.zip
