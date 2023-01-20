# Root is this location, normalized for symlinks
Root=$(cd "$(dirname "$BASH_SOURCE")"; cd -P "$(dirname "$(readlink "$BASH_SOURCE" || echo .)")"; pwd)
# SettingsDir is the location of my Bash settings
SettingsDir="$Root/settings"
# ExecDir is the locaton of my userspace executables
ExecDir="$HOME/.local/bin"

# Set the force-reload flag
[[ $1 == reload ]] && Reload=1 || Reload=0

EphemeralVars=( Reload Root SettingsDir ExecDir ) # vars to cleanup

source "$Root/lib/support.bash" # support functions - we leave these in the global namespace
source "$Root/lib/initutil.bash" # init utilities - we unset these after init

# init::toggle_debug # TODO: flag opts
# Turn off expansion i.e. no need to quote vars from here onward, until we turn it back on
support::splitspace off
support::globbing off

# Only source env vars if this is the first login or a force-reload
{ init::login? || (( Reload )); } && source $SettingsDir/env.bash

source $Root/lib/apps.bash $1 # app-specific environment and commands

init::debug 'Loading primary aliases'
source $SettingsDir/alias.bash # aliases

init::debug 'Loading primary commands'
# commands - contents must be quoted as they'll run in
# other envs where globbing/splitspace may be on
source $SettingsDir/cmd.bash

# Source interactive settings only if we're in an interactive shell
support::interactive? && {
  init::debug 'Loading primary interactive'
  source $SettingsDir/interactive.bash
}

# Source login settings only if we're logging in for the first time
# and in an interactive shell
{
  (support::interactive? && init::login?) || (( Reload ));
} && {
  init::debug 'Loading primary login'
  source $SettingsDir/login.bash
}

# Set the global login flag so we can dedupe login sourcing
init::set_login

# Cleanup
support::splitspace on
support::globbing on
unset -f "${EphemeralFunctions[@]}" # Remove functions declared in init:: namespace
unset -v "${EphemeralVars[@]}" # Remove ephemeral vars
