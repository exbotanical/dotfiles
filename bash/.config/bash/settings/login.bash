# Copy scripts to user-local executables dir
(
  support::globbing on

  for file in $Root/scripts/*; do
    chmod u+x $file
    file_name=$(basename $file)
    cp -u $file $ExecDir/${file_name%.*}
  done
)

# Start X
# [ -z $DISPLAY ] && [ $XDG_VTNR -eq 1 ] && exec startx

# Ask for password now and get it over with
# We'll probably want to upgrade the system soon
# sudo -v TODO: re-enable after fixing arch HD I/O errors
