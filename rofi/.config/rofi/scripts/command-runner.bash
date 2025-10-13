#!/usr/bin/env bash

# Enhanced Rofi Command Runner
# Provides aliases, functions, and arbitrary commands
# Shows output via notifications

set -euo pipefail

BASH_CONFIG_DIR="$HOME/.config/bash"
CACHE_DIR="$HOME/.cache/rofi"
HISTORY_FILE="$CACHE_DIR/command-history"
MAX_HISTORY=20
MAX_OUTPUT_LENGTH=200

# Retrieves cached aliases and functions
get_available_commands() {
  local aliases_cache="$CACHE_DIR/aliases-cache"
  local functions_cache="$CACHE_DIR/functions-cache"

  # Use cached files if they exist, otherwise show fallback message
  if [[ -f "$aliases_cache" ]]; then
    cat "$aliases_cache"
    echo ""
  else
    echo "# Aliases"
    echo "# (Cache not found - run 'reload' to refresh)"
    echo ""
  fi

  if [[ -f "$functions_cache" ]]; then
    cat "$functions_cache"
  else
    echo "# Functions"
    echo "# (Cache not found - run 'reload' to refresh)"
  fi
}

# Retrieves command history
get_command_history() {
  if [[ -f "$HISTORY_FILE" ]]; then
    echo ""
    echo "# Recent Commands"
    head -n "$MAX_HISTORY" "$HISTORY_FILE" | sed 's/$/ (recent)/'
  fi
}

# Adds command to history
# Arguments:
#   $1=command
add_to_history() {
  local cmd="$1"

  # Remove the command if it already exists, then add it to the top
  if [[ -f "$HISTORY_FILE" ]]; then
    grep -v "^$cmd$" "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" 2> /dev/null || touch "${HISTORY_FILE}.tmp"
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
  fi

  # Add to top and limit history size
  echo "$cmd" > "${HISTORY_FILE}.new"
  if [[ -f "$HISTORY_FILE" ]]; then
    head -n $((MAX_HISTORY - 1)) "$HISTORY_FILE" >> "${HISTORY_FILE}.new"
  fi
  mv "${HISTORY_FILE}.new" "$HISTORY_FILE"
}

# Executes command with proper environment
# Arguments:
#   $1=command
execute_command() {
  local cmd="$1"
  local temp_script=$(mktemp)

  cat > "$temp_script" << EOF
#!/usr/bin/env bash
# Source bash configuration to get aliases and functions
source "$BASH_CONFIG_DIR/init.bash" 2>/dev/null || true

# Enable alias expansion in non-interactive shell
shopt -s expand_aliases
# Disable hash table to ensure alias resolution works properly
set +h

# Execute the command
$cmd
EOF

  chmod +x "$temp_script"

  local output
  local exit_code=0

  notify-send -t 2000 -i "system-run" "Running Command" "$cmd" &

  if output=$(bash "$temp_script" 2>&1); then
    # Success case
    local truncated_output="$output"
    if [[ ${#output} -gt $MAX_OUTPUT_LENGTH ]]; then
      truncated_output="${output:0:$MAX_OUTPUT_LENGTH}..."
    fi

    if [[ -n "$output" ]]; then
      notify-send -t 8000 -i "dialog-information" "Command Completed" "$cmd\n\nOutput: $truncated_output"
    else
      notify-send -t 4000 -i "dialog-information" "Command Completed" "$cmd\n\n(No output)"
    fi
  else
    # Failure case
    exit_code=$?

    local truncated_output="$output"
    if [[ ${#output} -gt $MAX_OUTPUT_LENGTH ]]; then
      truncated_output="${output:0:$MAX_OUTPUT_LENGTH}..."
    fi

    notify-send -t 10000 -u critical -i "dialog-error" "Command Failed" "$cmd\n\nError: $truncated_output"
  fi

  rm -f "$temp_script"
  return $exit_code
}

# Sanitizes command (remove type annotations)
# Arguments:
#   $1=command
clean_command() {
  local cmd="$1"
  # Remove type annotations like " (alias)", " (function)", " (recent)"
  echo "$cmd" | sed 's/ (alias)$//' | sed 's/ (function)$//' | sed 's/ (recent)$//'
}

main() {
  mkdir -p "$CACHE_DIR"

  if [[ $# -eq 0 ]]; then
    # Show available commands
    {
      get_available_commands
      get_command_history
      echo ""
      echo "# Type any command..."
    }
  else
    # Execute the given command
    selected_cmd="$*"
    clean_cmd=$(clean_command "$selected_cmd")

    # Add to history (only if it's not a type annotation line)
    if [[ ! "$selected_cmd" =~ ^#.*$ ]] && [[ -n "$clean_cmd" ]]; then
      add_to_history "$clean_cmd"

      (execute_command "$clean_cmd") &
    fi
  fi
}

main $*
