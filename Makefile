ROOT_DIR     := root
INCLUDE_DIRS := $(filter-out $(ROOT_DIR)/ node_modules/, $(wildcard */))
MAKE_DIRS    := $(patsubst %/,%,$(dir $(wildcard */Makefile .[!.]*/Makefile)))
AL2_HOME     := /local/home/$$USER

.PHONY: bootstrap
bootstrap:
	$(MAKE) -C .bootstrap

.PHONY: postinstall
postinstall:
	./.dev/each-package.bash postinstall $(MAKE_DIRS)

.PHONY: install
install: deps
	mkdir -p $$HOME/.local/bin
	stow --verbose 3 --target=$$HOME --restow $(INCLUDE_DIRS)
	$(MAKE) postinstall
	$(MAKE) hooks

.PHONY: install_root
install_root:
	stow --verbose 3 --target=/ --restow $(ROOT_DIR)

.PHONY: install_al2
install_al2:
	mkdir -p $(AL2_HOME)/.local/bin
	stow --verbose 3 --target=$(AL2_HOME) --restow $(INCLUDE_DIRS)
	$(MAKE) postinstall
	$(MAKE) hooks
	$(MAKE) -C npm

.PHONY: delete
delete:
	stow --verbose --target=$$HOME --delete $(INCLUDE_DIRS)

.PHONY: simulate
simulate:
	stow --verbose 3 --target=$$HOME --simulate $(INCLUDE_DIRS)

.PHONY: unit_test
unit_test:
	./.dev/each-package.bash unit_test $(MAKE_DIRS)

.PHONY: integ_test
integ_test:
	$(MAKE) -C .dev integ_test

.PHONY: deps
deps:
	@for dir in $(wildcard */); do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C $$dir || exit 1; \
		fi \
	done

.PHONY: fmt
fmt:
	npm run fmt

.PHONY: fmt_check
fmt_check:
	npm run fmt:check

.PHONY: lint
lint:
	npm run lint

.PHONY: lint_fix
lint_fix:
	npm run lint:fix

.PHONY: hooks
hooks:
	$(MAKE) -C .githooks
