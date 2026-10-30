# Opens directories in pcmanfm. VSCodium's desktop entry also claims inode/directory and sorts
# first in mimeinfo.cache, so xdg-open picks VSCodium while no default is set.
readonly MIME_TYPE=inode/directory
readonly HANDLER=pcmanfm.desktop

if [[ $(xdg-mime query default "$MIME_TYPE") == "$HANDLER" ]]; then
  log "[=] $MIME_TYPE: $HANDLER"
  exit 0
fi

xdg-mime default "$HANDLER" "$MIME_TYPE"
log "[+] $MIME_TYPE: $HANDLER"
