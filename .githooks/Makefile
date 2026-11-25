.PHONY: all

all:
	@command -v npm >/dev/null || { echo 'hooks: npm not found; install node, then run `make hooks`' >&2; exit 1; }
	npm ci --prefix ..
	git config --local core.hooksPath .githooks
	git config --local filter.pcmanfm-geometry.clean "sed -E '/^(win_width|win_height|maximized|splitter_pos)=/d'"
