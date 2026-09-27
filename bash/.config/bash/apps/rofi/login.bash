#!/usr/bin/env bash

# Rofi command cache refresh script
# This runs on login to populate the rofi command cache

# Configuration
CACHE_DIR="$HOME/.cache/rofi"
ALIASES_CACHE="$CACHE_DIR/aliases-cache"
FUNCTIONS_CACHE="$CACHE_DIR/functions-cache"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

init::debug 'Refreshing rofi command cache'

# Generate aliases cache (use >| to force overwrite)
{
  echo "# Aliases"
  # Use command alias to avoid ripgrep issues
  command alias | command grep -E '^[a-zA-Z]' | sed 's/alias //' | sed "s/='.*'/ (alias)/" | head -20
} >| "$ALIASES_CACHE"

# Generate functions cache (use >| to force overwrite)
{
  echo "# Functions"
  # Extract function names from cmd.bash
  if [[ -f "$RootDir/src/cmd.bash" ]]; then
    command grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\s*\)' "$RootDir/src/cmd.bash" \
      | sed 's/\s*().*/ (function)/' | head -15
  fi
} >| "$FUNCTIONS_CACHE"

init::debug "Rofi cache refreshed: aliases=$ALIASES_CACHE, functions=$FUNCTIONS_CACHE"
