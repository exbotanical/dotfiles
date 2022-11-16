INSTALL_DIR=./install

.PHONY: install
install:
	stow --verbose 3 --target=$$HOME --restow */
	$(foreach file, $(wildcard $(INSTALL_DIR)/*), ./$(file))

.PHONY: delete
delete:
	stow --verbose --target=$$HOME --delete */

.PHONY: simulate
simulate:
	stow --verbose 3 --target=$$HOME --simulate */

.PHONY: test
test:
	find . -path ./.git -prune -o -type f -print | bash -c "shpec $1"
