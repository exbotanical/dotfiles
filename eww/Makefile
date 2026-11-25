.PHONY: all postinstall

all:

# Reloads a running eww daemon, because a listener keeps running the script it started with
# until the daemon restarts it, and eww reload can exit nonzero after the daemon has reloaded.
# Without a daemon, e.g. after bootstrap replaced the eww package, it opens the bars in the X
# session; bash's postinstall, which runs first, has installed the bar script.
postinstall:
	@if command -v eww > /dev/null && eww ping > /dev/null 2>&1; then \
		eww reload > /dev/null 2>&1 || true; \
		echo 'eww: reloaded the running daemon'; \
	elif [ -n "$${DISPLAY:-}" ] && command -v bar > /dev/null; then \
		setsid -f bar > /dev/null 2>&1 < /dev/null; \
		echo 'eww: opened the bars'; \
	fi
