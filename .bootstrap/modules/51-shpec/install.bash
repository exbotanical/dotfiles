# The shpec installer runs `make install` with PREFIX=/usr/local, which needs root.
if has shpec; then
  log '[=] shpec'
  exit 0
fi
curl -fsSL https://raw.githubusercontent.com/rylnd/shpec/master/install.sh | sudo sh
