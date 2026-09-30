.PHONY: install install_al2 delete simulate unit_test deps postinstall fmt fmt_check lint lint_fix hooks

INSTALL_DIR  := .install
ROOT_DIR     := root
INCLUDE_DIRS := $(filter-out $(ROOT_DIR)/ node_modules/, $(wildcard */))
AL2_HOME     := /local/home/$$USER

postinstall:
	./$(INSTALL_DIR)/postinstall.bash

install: deps
	mkdir -p $$HOME/.local/bin
	stow --verbose 3 --target=$$HOME --restow $(INCLUDE_DIRS)
	$(MAKE) postinstall
	$(MAKE) hooks

install_root:
	stow --verbose 3 --target=/ --restow $(ROOT_DIR)

install_al2:
	mkdir -p $(AL2_HOME)/.local/bin
	stow --verbose 3 --target=$(AL2_HOME) --restow $(INCLUDE_DIRS)
	HOME=$(AL2_HOME) ./$(INSTALL_DIR)/al2.bash
	$(MAKE) postinstall
	$(MAKE) hooks

delete:
	stow --verbose --target=$$HOME --delete $(INCLUDE_DIRS)

simulate:
	stow --verbose 3 --target=$$HOME --simulate $(INCLUDE_DIRS)

unit_test:
	find . -path ./.git -prune -o -type f -print | bash -c "shpec $1"

deps:
	@for dir in $(wildcard */); do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C $$dir || exit 1; \
		fi \
	done

fmt:
	npm run fmt

fmt_check:
	npm run fmt:check

lint:
	npm run lint

lint_fix:
	npm run lint:fix

hooks:
	@command -v npm >/dev/null || { echo 'hooks: npm not found; install node, then run `make hooks`' >&2; exit 1; }
	npm ci
	git config --local core.hooksPath .githooks
