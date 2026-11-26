#!/usr/bin/env bash
# Closes an X window whose client has stopped responding. It asks i3 to close the window, then
# sends SIGTERM and finally SIGKILL to the process named by the window's _NET_WM_PID, waiting up
# to 2 seconds after each step. Before SIGKILL it writes each thread's scheduler state and kernel
# wait channel to ~/.cache/kill_dead_window/, which records where the process was blocked. It
# refuses to signal a process that owns other i3 windows, because the signal would close them too.
# Usage: kill_dead_window, then click the window to close

readonly POLL_SECONDS=0.1
readonly POLL_ATTEMPTS=20

die () {
  printf 'kill_dead_window: %s\n' "$@" >&2
  exit 1
}

usage () {
  printf '%s\n' 'Usage: kill_dead_window, then click the window to close'
}

# Succeeds as soon as the given command succeeds, and fails once POLL_ATTEMPTS polls have failed.
wait_until () {
  local attempt
  for ((attempt = 0; attempt < POLL_ATTEMPTS; attempt++)); do
    "$@" && return 0
    sleep "$POLL_SECONDS"
  done
  return 1
}

window_gone () {
  ! xdotool getwindowname "$1" > /dev/null 2>&1
}

# Succeeds when process $1 has exited, including an exited process its parent has not yet reaped.
process_gone () {
  local state
  state=$(ps -o stat= -p "$1") || return 0
  [[ $state == Z* ]]
}

# Prints the X window IDs of every window in i3 tree JSON $1, one per line.
managed_windows () {
  jq -r '.. | objects | select(.window != null) | .window' <<< "$1"
}

# Succeeds when a window in i3 tree JSON $3, other than window $2, belongs to process $1.
owns_other_windows () {
  local pid=$1 window=$2 tree=$3 other
  while read -r other; do
    if [[ $other != "$window" && $(xdotool getwindowpid "$other" 2> /dev/null) == "$pid" ]]; then
      return 0
    fi
  done < <(managed_windows "$tree")
  return 1
}

# Writes the command line of process $1 to file $2, then one line per thread: thread ID, name,
# scheduler state, and the kernel function the thread is waiting in.
write_thread_report () {
  local pid=$1 report=$2 task stat state
  {
    tr '\0' ' ' < "/proc/$pid/cmdline"
    printf '\n'
    for task in "/proc/$pid/task/"*; do
      stat=$(< "$task/stat")
      state=${stat##*) }
      printf '%s %s %s %s\n' "${task##*/}" "$(< "$task/comm")" "${state%% *}" "$(< "$task/wchan")"
    done
  } > "$report"
}

main () {
  local opt window pid report_dir report
  while getopts ':h' opt; do
    case $opt in
      h)
        usage
        return 0
        ;;
      *)
        usage >&2
        return 2
        ;;
    esac
  done

  window=$(xdotool selectwindow) || die 'no window was selected'
  pid=$(xdotool getwindowpid "$window") || die "window $window has no _NET_WM_PID"

  i3-msg "[id=$window] kill" > /dev/null || die "i3 could not close window $window"
  if wait_until window_gone "$window"; then
    printf 'kill_dead_window: window %s closed\n' "$window"
    return 0
  fi

  if owns_other_windows "$pid" "$window" "$(i3-msg -t get_tree)"; then
    die "process $pid owns other windows; it was not signalled"
  fi

  kill -TERM "$pid" || die "SIGTERM to process $pid failed"
  if wait_until process_gone "$pid"; then
    printf 'kill_dead_window: process %s exited on SIGTERM\n' "$pid"
    return 0
  fi

  report_dir="${XDG_CACHE_HOME:-$HOME/.cache}/kill_dead_window"
  mkdir -p "$report_dir" || die "creating $report_dir failed"
  report="$report_dir/$(date +%Y%m%dT%H%M%S)-$pid.log"
  write_thread_report "$pid" "$report" \
    || printf 'kill_dead_window: thread report %s is incomplete\n' "$report" >&2
  kill -KILL "$pid" || die "SIGKILL to process $pid failed"
  wait_until process_gone "$pid" || die "process $pid survived SIGKILL; see $report"
  printf 'kill_dead_window: process %s killed with SIGKILL; thread report: %s\n' "$pid" "$report"
}

# stop here if being sourced
return 2> /dev/null

set -euo pipefail

main "$@"
