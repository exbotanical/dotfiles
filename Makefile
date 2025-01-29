.PHONY: install install_osx install_al2 delete simulate test deps

INSTALL_DIR  =./install
ROOT_DIR  =root
INCLUDE_DIRS =$(filter-out $(ROOT_DIR)/, $(wildcard */))
AL2_HOME     =/local/home/$$USER

install: deps
	mkdir -p $$HOME/.local/bin
	stow --verbose 3 --target=$$HOME --restow $(INCLUDE_DIRS)
	$(foreach file, $(wildcard $(INSTALL_DIR)/*), ./$(file))

install_root:
	stow --verbose 3 --target=/ --restow $(ROOT_DIR)

install_osx: node_modules
	$(MAKE) install
# UGH: https://savannah.gnu.org/bugs/?712
	./install/osx.bash

install_al2:
	mkdir -p $(AL2_HOME)/.local/bin
	stow --verbose 3 --target=$(AL2_HOME) --restow */
	$(foreach file, $(wildcard $(INSTALL_DIR)/*), ./$(file))

delete:
	stow --verbose --target=$$HOME --delete */

simulate:
	stow --verbose 3 --target=$$HOME --simulate */

test:
	find . -path ./.git -prune -o -type f -print | bash -c "shpec $1"

deps:
	@for dir in $(wildcard */); do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C $$dir; \
		fi \
	done
