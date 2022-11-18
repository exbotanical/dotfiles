# Run shpec e.g. `tdd t/test.shpec.bash`
# shellcheck disable=SC2142
alias tdd='find . -path ./.git -prune -o -type f -print | entr bash -c "shpec $1"'
