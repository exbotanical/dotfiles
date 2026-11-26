RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_utils.bash"
source "$RootDir/../.config/bash/scripts/kill_dead_window.bash"

# Windows 11 and 22 are tiled in a nested container, and 33 is floating; containers have no window.
TREE='{"window": null, "nodes": [{"window": null, "nodes": [{"window": 11, "nodes": []},
  {"window": 22, "nodes": [], "floating_nodes": []}],
  "floating_nodes": [{"window": null, "nodes": [{"window": 33, "nodes": []}]}]}]}'

describe 'kill_dead_window'
  describe 'managed_windows'
    it 'prints tiled and floating windows and skips containers'
      result=$(managed_windows "$TREE")
      assert equal $'11\n22\n33' "$result"
    ti
  end_describe

  describe 'owns_other_windows'
    it 'succeeds only when another window belongs to the same process'
      xdotool () {
        case $2 in
          11 | 22) printf '100\n' ;;
          33) printf '200\n' ;;
        esac
      }
      result=$(for args in '100 11' '100 22' '200 33' '300 11'; do
        owns_other_windows ${args% *} ${args#* } "$TREE"
        printf '%s=%s\n' "$args" $?
      done)
      assert equal $'100 11=0\n100 22=0\n200 33=1\n300 11=1' "$result"
    ti

    it 'fails for an empty tree'
      owns_other_windows 100 11 '{"window": null, "nodes": []}'
      assert equal 1 $?
    ti
  end_describe

  describe 'process_gone'
    it 'fails for a running process and succeeds once it has exited'
      sleep 30 &
      pid=$!
      process_gone $pid
      running=$?
      kill $pid
      wait $pid 2> /dev/null
      process_gone $pid
      assert equal '1 0' "$running $?"
    ti
  end_describe

  describe 'write_thread_report'
    alias setup='dir=$(mktemp -d) || return; sleep 30 & pid=$!'
    alias teardown='kill $pid; rm -rf $dir'

    it 'writes the command line, then the thread ID, name, and state of each thread'
      sleep 0.2
      write_thread_report $pid $dir/report
      mapfile -t lines < $dir/report
      [[ ${#lines[@]} == 2 && ${lines[0]} == 'sleep 30 ' && ${lines[1]} == "$pid sleep S "* ]]
      assert equal 0 $?
    ti
  end_describe

  describe 'main'
    alias setup='dir=$(mktemp -d) || return'
    alias teardown='rm -rf $dir'

    # Window 11 belongs to process 100, and window 22 to process OWNER_OF_22. Files in $dir record
    # the window closing and the process exiting, so each stub reports the state that the earlier
    # stub calls produced.
    stub_session () {
      xdotool () {
        case $1 in
          selectwindow) printf '11\n' ;;
          getwindowpid) [[ $2 == 11 ]] && printf '100\n' || printf '%s\n' "$OWNER_OF_22" ;;
          getwindowname) [[ ! -e $dir/closed ]] ;;
        esac
      }
      i3-msg () {
        if [[ $1 == -t ]]; then
          printf '%s\n' "$TREE"
        elif [[ $CLOSES == true ]]; then
          touch $dir/closed
        fi
      }
      kill () { [[ $1 == "-$EXITS_ON" ]] && touch $dir/exited; return 0; }
      ps () { [[ ! -e $dir/exited ]] && printf 'Sl\n'; }
      sleep () { :; }
    }

    it 'stops after i3 closes the window'
      CLOSES=true EXITS_ON=none OWNER_OF_22=200
      stub_session
      result=$(main)
      assert equal 'kill_dead_window: window 11 closed' "$result"
    ti

    it 'exits on SIGTERM when the window ignores the close request'
      CLOSES=false EXITS_ON=TERM OWNER_OF_22=200
      stub_session
      result=$(main)
      assert equal 'kill_dead_window: process 100 exited on SIGTERM' "$result"
    ti

    it 'refuses to signal a process that owns other windows'
      CLOSES=false EXITS_ON=TERM OWNER_OF_22=100
      stub_session
      (main) 2> /dev/null
      assert equal 1 $?
    ti

    it 'exits nonzero when the process survives SIGKILL'
      CLOSES=false EXITS_ON=none OWNER_OF_22=200 XDG_CACHE_HOME=$dir
      stub_session
      write_thread_report () { :; }
      (main) 2> /dev/null
      assert equal 1 $?
    ti

    it 'exits 1 when no window is selected'
      CLOSES=true EXITS_ON=TERM OWNER_OF_22=200
      stub_session
      xdotool () { return 1; }
      (main) 2> /dev/null
      assert equal 1 $?
    ti

    it 'exits 2 on an unknown option'
      (main -x) > /dev/null 2>&1
      assert equal 2 $?
    ti
  end_describe
end_describe
