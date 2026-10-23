# TODOs

- [ ] test init.bash
- [x] test other support, init, cmd
- [x] add install script to symlink init.bash
- [x] Add debug mode to bash config
- [ ] Add contexts
- [ ] enable shellcheck expansion, globbing rules in alias and cmd files
- [ ] bash macros (copies file into other file)
- [x] arch logo in status bar
- [ ] chron task to cleanup music script images
- [ ] add status bar news panel
- [x] modularize and reuse eww widgets
- [ ] automate setup
- [ ] dark screen cover alarm
- [x] fix battery script low battery notif (dedupe)
- [ ] fix music/player script on X
- [ ] fix eww popups on X
- [ ] xdg settings
- [ ] thunar settings
- [ ] seed the arch and al2023 bootstrap package lists, then prune each to the packages the dotfiles use
  - arch: `pacman -Qqen` into `.bootstrap/packages/arch/pacman.{base,desktop}.txt`, `pacman -Qqem` into `.bootstrap/packages/arch/aur.desktop.txt`
  - al2023: `dnf repoquery --userinstalled --qf '%{name}'` into `.bootstrap/packages/al2023/dnf.base.txt`
  - al2023: decide between SPAL and a source build for stow (and lsd), since `make install` needs stow

## Deps

### Wayland

#### Eww

- jaq
- gojq
- ripgrep
- blueman (blueberry?)
- ~~wireplumber~~
- nmcli
- ~~pipewire-pulse (replace pulseaudio from X)~~
- ~~iwgtk~~ nm-applet

- themeing
  - dircolors
  - btop
  - dunst
  - eww
  - hexchat
  - htop
  - i3
  - vim
  - rofi
  - vscodium
  - x11/gtk
