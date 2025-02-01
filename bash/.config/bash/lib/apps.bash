pushd $RootDir/apps >/dev/null

APP_LIST=$(
  init::list_dir . |
  utils::filter utils::dir? |
  utils::filter init::load_app? |
  init::order_by_dependencies
)

# Load app-specific configurations, only if that app exists
# and meets the predicate conditions for this environment (if any).
for app in $APP_LIST; do
  init::debug "Loading configurations for $app"

  { init::login? || [[ $1 == reload ]] || init::in_vscodium?; } && {
    init::debug "Loading env and login configs for $app if present"
    init::source? $app/env.bash
    init::source? $app/login.bash
  }

  utils::splitspace on
  utils::globbing on
  init::source? "$app"/init.bash

  utils::splitspace off
  utils::globbing off

  init::source? $app/interactive.bash
  init::source? $app/alias.bash
  init::source? $app/cmd.bash
done

unset -v APP_LIST app
popd >/dev/null
