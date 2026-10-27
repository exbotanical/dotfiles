# shpec has no shebang, so the recipe shell must be bash for shpec and its tests to run as bash.
SHELL := bash

.PHONY: all postinstall unit_test

all:

postinstall:
	ln -sf $(HOME)/.config/bash/init.bash $(HOME)/.bashrc
	ln -sf $(HOME)/.config/bash/init.bash $(HOME)/.bash_profile

unit_test:
	shpec tests/*_shpec.bash
