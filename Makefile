INSTALL_DIR=./install

.PHONY: install
install:
	mkdir -p $$HOME/.local/bin
	stow --verbose 3 --target=$$HOME --restow */
	$(foreach file, $(wildcard $(INSTALL_DIR)/*), ./$(file))

.PHONY: install_osx
install_osx:
	$(MAKE) install
	# UGH: https://savannah.gnu.org/bugs/?712
	./install/osx.bash

.PHONY: delete
delete:
	stow --verbose --target=$$HOME --delete */

.PHONY: simulate
simulate:
	stow --verbose 3 --target=$$HOME --simulate */

.PHONY: test
test:
	find . -path ./.git -prune -o -type f -print | bash -c "shpec $1"
