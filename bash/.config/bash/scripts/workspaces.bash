#!/usr/bin/env bash

# Places each numbered workspace on a monitor by the monitors' left-to-right
# order: 1-2 on the first, 3 on the second, 4 and up on the third. With fewer
# monitors, workspaces fall back to the rightmost one.
# Usage: workspaces

set -euo pipefail

die () {
  printf '%s\n' "$@" >&2
  exit 1
}

# Prints one i3 command per workspace that holds windows. Criteria select a
# workspace through its windows, so the move neither focuses the workspace nor
# fails on an empty one; i3 destroys empty workspaces once they lose focus.
placement_commands () {
  jq -nr --argjson outputs "$1" --argjson tree "$2" '
    ([$outputs[] | select(.active)] | sort_by(.rect.x) | map(.name)) as $ranked
    | $tree
    | ..
    | objects
    | select(.type == "workspace" and .num >= 1 and .name == (.num | tostring))
    | select((.nodes | length) + (.floating_nodes | length) > 0)
    | (if .num <= 2 then 0 elif .num == 3 then 1 else 2 end) as $rank
    | $ranked[[$rank, ($ranked | length) - 1] | min] as $output
    | "[workspace=\"^\(.name)$\"] move workspace to output \($output)"
  '
}

main () {
  command -v jq > /dev/null || die 'workspaces: jq is not installed; no workspaces were moved'

  local commands
  commands=$(placement_commands "$(i3-msg -t get_outputs)" "$(i3-msg -t get_tree)")

  if [[ -n $commands ]]; then
    i3-msg "${commands//$'\n'/; }" > /dev/null
  fi
}

main
