# Installs vim-plug and the plugins in ~/.vimrc, which 90-dotfiles links.
readonly PLUG=$HOME/.vim/autoload/plug.vim
readonly VIM=(vim -N -es -u "$HOME/.vimrc" -i NONE)

if [[ ! -f $PLUG ]]; then
  curl -fsSLo "$PLUG" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# ~/.vimrc uses plugins (e.g. its colorscheme) that do not exist until PlugInstall finishes, so
# vim exits non-zero on the run that installs them. A clean startup afterwards is the check.
"${VIM[@]}" -c 'PlugInstall --sync' -c qa || true
"${VIM[@]}" -c qa || die 'vim reports errors loading ~/.vimrc after PlugInstall'
