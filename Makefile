INSTALL_DIR=./install
AL2_HOME=/local/home/$$USER

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

.PHONY: install_al2
install_al2:
	mkdir -p $(AL2_HOME)/.local/bin
	stow --verbose 3 --target=$(AL2_HOME) --restow */
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
