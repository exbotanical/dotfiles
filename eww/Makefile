.PHONY: all postinstall

all:

# Reloads a running eww daemon, because a listener keeps running the script it started with
# until the daemon restarts it. eww reload can exit nonzero after the daemon has reloaded.
postinstall:
	@if command -v eww > /dev/null && eww ping > /dev/null 2>&1; then \
		eww reload > /dev/null 2>&1 || true; \
		echo 'eww: reloaded the running daemon'; \
	fi
