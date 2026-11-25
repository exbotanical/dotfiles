# Installs the GTK, icon, and cursor themes that x11/.config/theme.env names. Neither distro
# packages them under these names. Cursors go to ~/.icons because libXcursor searches
# ~/.icons:/usr/share/icons:/usr/share/pixmaps by default; icons go to ~/.local/share/icons,
# which GTK searches.
readonly THEMES_DIR=$HOME/.themes
readonly ICONS_DIR=$HOME/.local/share/icons
readonly CURSORS_DIR=$HOME/.icons

source "$REPO_DIR/x11/.config/theme.env"

module::applies () {
  [[ $PROFILE == desktop ]]
}

module::install () {
  work=
  trap 'rm -rf "${work:-}"' EXIT

  install_theme "$THEMES_DIR/$GTK_THEME" "$GTK_THEME_DIR" "$GTK_THEME_URL"
  install_theme "$ICONS_DIR/$ICON_THEME" "$ICON_THEME_DIR" "$ICON_THEME_URL"
  install_theme "$CURSORS_DIR/$CURSOR_THEME" "$CURSOR_THEME_DIR" "$CURSOR_THEME_URL"
}

# Reports each theme URL that downloads a GitHub release asset whose release tag is not the
# newest. The other URLs name a branch or an attachment, which have no version.
module::outdated () {
  local url repo tag
  for url in "$GTK_THEME_URL" "$ICON_THEME_URL" "$CURSOR_THEME_URL"; do
    [[ $url =~ ^https://github\.com/([^/]+/[^/]+)/releases/download/([^/]+)/ ]] || continue
    repo=${BASH_REMATCH[1]}
    tag=${BASH_REMATCH[2]}
    bootstrap::report_outdated "$repo" "$tag" "$(bootstrap::latest_tag "https://github.com/$repo")"
  done
}

# Downloads the zip at $3 and moves its top-level directory $2 to $1, unless $1 exists.
install_theme () {
  local dest=$1 top=$2 url=$3
  local name=${dest#"$HOME"/}

  if [[ -d $dest ]]; then
    log "[=] $name"
    return
  fi

  # Extracts beside the destination so that the final mv is a rename, and an interrupted run
  # leaves no partial theme at $dest for the next run to skip.
  mkdir -p "${dest%/*}"
  work=$(mktemp -d "${dest%/*}/.theme.XXXXXX")
  curl -fsSLo "$work/theme.zip" "$url"
  unzip -q "$work/theme.zip" -d "$work"
  mv "$work/$top" "$dest"
  rm -rf "$work"
  log "[+] $name"
}
