.PHONY: all
.DELETE_ON_ERROR:

all:
# GTK apps like lxappearance like to modify these files and invalid the symlinks created by stow.
# We remove and re-link when running stow until a less hacky workaround is found.
# A path that already resolves to the package file is skipped: when stow folds ~/.config/gtk-3.0
# into a directory symlink, rm would follow it and delete the file from the repo.
# TODO: Fix
	@cd ~ && for file in .gtkrc-2.0 .config/gtk-3.0/settings.ini; do \
		if [ "$$file" -ef "$(CURDIR)/$$file" ]; then continue; fi; \
		if [ -e "$$file" ] || [ -L "$$file" ]; then rm "$$file"; fi; \
	done
