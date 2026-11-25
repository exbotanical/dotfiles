# shpec has no shebang, so the recipe shell must be bash for shpec and its tests to run as bash.
SHELL := bash

.PHONY: all outdated unit_test

all:
	./bootstrap.bash

outdated:
	./bootstrap.bash outdated

unit_test:
	shpec tests/*_shpec.bash
