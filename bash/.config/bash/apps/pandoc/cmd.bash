# rmd renders a markdown file
rmd () {
  pandoc "$1" | lynx -stdin
}
