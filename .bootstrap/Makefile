# shpec has no shebang, so the recipe shell must be bash for shpec and its tests to run as bash.
SHELL := bash

.PHONY: all unit_test

all:
	./bootstrap.bash

unit_test:
	shpec tests/*_shpec.bash
