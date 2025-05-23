.PHONY: install install_osx install_al2 delete simulate unit_test deps postinstall

INSTALL_DIR  := .install
ROOT_DIR     := root
INCLUDE_DIRS := $(filter-out $(ROOT_DIR)/, $(wildcard */))
AL2_HOME     := /local/home/$$USER

postinstall:
	./$(INSTALL_DIR)/postinstall.bash

install: deps
	mkdir -p $$HOME/.local/bin
	stow --verbose 3 --target=$$HOME --restow $(INCLUDE_DIRS)
	$(MAKE) postinstall

install_root:
	stow --verbose 3 --target=/ --restow $(ROOT_DIR)

install_osx: node_modules
	$(MAKE) install
# UGH: https://savannah.gnu.org/bugs/?712
	./$(INSTALL_DIR)/osx.bash
	$(MAKE) postinstall

install_al2:
	mkdir -p $(AL2_HOME)/.local/bin
	stow --verbose 3 --target=$(AL2_HOME) --restow $(INCLUDE_DIRS)
	HOME=$(AL2_HOME) ./$(INSTALL_DIR)/al2.bash
	$(MAKE) postinstall

delete:
	stow --verbose --target=$$HOME --delete */

simulate:
	stow --verbose 3 --target=$$HOME --simulate */

unit_test:
	find . -path ./.git -prune -o -type f -print | bash -c "shpec $1"

deps:
	@for dir in $(wildcard */); do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C $$dir; \
		fi \
	done
