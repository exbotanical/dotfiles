# shpec has no shebang, so the recipe shell must be bash for shpec and its tests to run as bash.
SHELL := bash

.PHONY: all integ_test unit_test

all:

integ_test:
	./run-integ.bash

unit_test:
	shpec tests/*_shpec.bash
