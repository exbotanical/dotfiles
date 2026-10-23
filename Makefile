.PHONY: install install_al2 delete simulate unit_test integ_test deps postinstall fmt fmt_check lint lint_fix hooks prettier_global

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
	$(MAKE) prettier_global

install_root:
	stow --verbose 3 --target=/ --restow $(ROOT_DIR)

install_al2:
	mkdir -p $(AL2_HOME)/.local/bin
	stow --verbose 3 --target=$(AL2_HOME) --restow $(INCLUDE_DIRS)
	$(MAKE) postinstall
	$(MAKE) hooks
	$(MAKE) prettier_global

delete:
	stow --verbose --target=$$HOME --delete $(INCLUDE_DIRS)

simulate:
	stow --verbose 3 --target=$$HOME --simulate $(INCLUDE_DIRS)

unit_test:
	find . -path ./.git -prune -o -type f -print | bash -c "shpec $1"

integ_test:
	./.dev/run-integ.bash

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

prettier_global:
	@command -v npm >/dev/null || { echo 'prettier_global: npm not found; install node, then run `make prettier_global`' >&2; exit 1; }
	@version=$$(node -p 'require("./package-lock.json").packages["node_modules/prettier"].version') || exit 1; \
		npm ls -g "prettier@$$version" >/dev/null || npm i -g "prettier@$$version"
