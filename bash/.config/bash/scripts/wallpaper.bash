#!/usr/bin/env bash

# Draws the wallpaper on every monitor
# Usage: wallpaper

set -euo pipefail

readonly WALLPAPER="$HOME/.config/assets/ghost.png"

feh --no-fehbg --bg-fill "$WALLPAPER"
