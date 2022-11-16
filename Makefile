all:
	stow --verbose 3 --target=$$HOME --restow */

delete:
	stow --verbose --target=$$HOME --delete */

simulate:
	stow --verbose 3 --target=$$HOME --simulate */

test:
	find . -path ./.git -prune -o -type f -print | bash -c "shpec $1"
