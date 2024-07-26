# pwdcp copies `cd $(pwd)` to the clipboard buffer and launches a new shell
# This is a workaround for annoying macos behavior whereby my GPG agent
# stops working in vscode's shitty terminal
pwdcp () {
  alacritty --hold -e sh -c "cd $(pwd); exec \"${SHELL:-sh}\" && reload" &
}
