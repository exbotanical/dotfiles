pushd $Root/apps >/dev/null

APP_LIST=$(
  init::list_dir .  \
  | support::filter support::dir? \
  | support::filter init::load_app?
)

# Load app-specific configurations, only if that app exists
# and meets the predicate conditions for this environment (if any).
for app in $APP_LIST; do
  { init::login? || [[ $1 == reload ]]; } && init::source? $app/env.bash

  support::splitspace on
  support::globbing on
  init::source? "$app"/init.bash

  support::splitspace off
  support::globbing off

  init::source? $app/interactive.bash
  init::source? $app/alias.bash
  init::source? $app/cmd.bash
done

unset -v APP_LIST app
popd >/dev/null
