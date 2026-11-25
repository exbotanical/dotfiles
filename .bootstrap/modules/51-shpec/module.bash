# Installs shpec. Its installer runs `make install` with PREFIX=/usr/local, which needs root.

module::applies () {
  :
}

module::install () {
  if has shpec; then
    log '[=] shpec'
    return 0
  fi
  curl -fsSL https://raw.githubusercontent.com/rylnd/shpec/master/install.sh | sudo sh
}

# The installer installs shpec's master branch, so there is no pin to compare.
module::outdated () {
  :
}
