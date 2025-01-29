.PHONY: all
.DELETE_ON_ERROR:

all:
# GTK apps like lxappearance like to modify these files and invalid the symlinks created by stow.
# We remove and re-link when running stow until a less hacky workaround is found.
# TODO: Fix
	rm ~/.gtkrc-2.0 ~/.config/gtk-3.0/settings.ini
