#!/usr/bin/env bash
#desc           :Install brew and necessary formulae and casks
#author         :Matthew Zito (mtzito@)
#===============================================================================

install_brew () {
  /bin/bash -c "$(curl -fsSL $BREW_INSTALL_SCRIPT)"
}

install_git () {
  brew install git
}

apply_brew_taps () {
  local tap_packages=${*:-${BREW_TAPS[@]}}

  for tap in $tap_packages; do
    if brew tap | grep "$tap" > /dev/null; then
      echo "Tap $tap is already applied"
    else
      brew tap "$tap"
    fi
  done
}

install_brew_casks () {
  local casks=${*:-${BREW_CASKS[@]}}

  for cask in $casks; do
    if brew list --casks | grep "$cask" > /dev/null; then
      echo "Cask $cask is already installed"
    else
      echo "Installing cask <$cask>..."
      brew install --cask "$cask"
    fi
  done
}

install_brew_formulae () {
  local formulae=${*:-${BREW_FORMULAE[@]}}

  for formula in $formulae; do
    if brew list --formula | grep "$formula" > /dev/null; then
      echo "Formula $formula is already installed"
    else
      echo "Installing package <$formula>..."
      brew install "$formula"
    fi
  done
}

install_git_completions () {
  local git_completions_f="$HOME/.git-completion.bash"
  curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o "$git_completions_f"
   . "$git_completions_f"
}

main () {
  if [[ $(which -s brew) != 0 ]]; then
    echo "Homebrew already installed"
    brew update
  else
    echo "Installing Homebrew..."
    install_brew
  fi

  if ! git --version &>/dev/null; then
    echo "Installing git..."
    install_git
  else
    echo "git already installed"
  fi

  apply_brew_taps "${BREW_TAPS[@]}"

  install_brew_casks "${BREW_CASKS[@]}"

  install_brew_formulae "${BREW_FORMULAE[@]}"

  install_git_completions
}

BREW_INSTALL_SCRIPT='https://raw.githubusercontent.com/Homebrew/install/master/install.sh'

BREW_TAPS=(
  'amazon/amazon'
  'homebrew/cask'
  'homebrew/cask-fonts'
  'homebrew/core'
  'homebrew/services'
  'koekeishiya/formulae'
)

BREW_CASKS=(
  'alacritty'
  'intellij-idea-ce'
  'font-fira-code'
  'vscodium',
  'font-hack-nerd-font'
  'aws/tap'
)

BREW_FORMULAE=(
  'bash'
  'icu4c'
  'openssl'
  'bash-completion@2'
  'libnghttp2'
  'pcre2'
  'brotli'
  'libuv'
  'readline'
  'c-ares'
  'libyaml'
  'ruby'
  'ca-certificates'
  'macos-term-size'
  'skhd'
  'fswatch'
  'ninja-dev-sync'
  'stow'
  'gettext'
  'node'
  'node@14'
  'yabai'
  'mas'
  'go'
  'oh-my-posh'
  'gpg2'
  'taskell'
  'htop'
  'jq'
  'neovim'
  'smithy-cli'
)

# stop here if being sourced
return 2>/dev/null

set -o errexit -o nounset

main
