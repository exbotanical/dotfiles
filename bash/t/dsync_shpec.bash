RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_utils.bash"
source "$RootDir/../.config/bash/scripts/dsync.bash"

describe 'dsync'
describe remote_dir_for
it 'maps a local directory under the remote root by basename'
cases=(
  '/home/me/work/Pkg||/home/me/sync|/home/me/sync/Pkg'
  '/home/me/work/Pkg/||/home/me/sync/|/home/me/sync/Pkg'
  '/home/me/work/Pkg|/srv/elsewhere/Pkg|/home/me/sync|/srv/elsewhere/Pkg'
  '/home/me/work/Pkg|/srv/elsewhere/Pkg/||/srv/elsewhere/Pkg'
)

for spec in "${cases[@]}"; do
  IFS='|' read -r local_dir explicit root expected <<< "$spec"
  assert equal "$expected" "$(remote_dir_for "$local_dir" "$explicit" "$root")"
done
ti

it 'fails when neither an explicit remote directory nor a root is given'
result=$(remote_dir_for /home/me/work/Pkg '' '' 2>&1)
status=$?
assert unequal 0 $status
ti
end_describe

describe endpoints_for
it 'orders source before destination and syncs directory contents'
result=$(endpoints_for push host /home/me/work/Pkg/ /home/me/sync/Pkg)
assert equal $'/home/me/work/Pkg/\nhost:/home/me/sync/Pkg/' "$result"
ti

it 'reverses the endpoints when pulling'
result=$(endpoints_for pull host /home/me/work/Pkg /home/me/sync/Pkg/)
assert equal $'host:/home/me/sync/Pkg/\n/home/me/work/Pkg/' "$result"
ti

it 'fails on an unknown direction'
result=$(endpoints_for sideways host /a /b 2>&1)
status=$?
assert unequal 0 $status
ti
end_describe

describe rsh_command
it 'joins the ssh flags on spaces even when IFS is a newline'
expected="ssh -o ControlMaster=auto -o ControlPath=${XDG_RUNTIME_DIR:-/tmp}/dsync-%C -o ControlPersist=10m"

result=$(
  IFS=$'\n'
  rsh_command
)
assert equal "$expected" "$result"
ti
end_describe

describe exclude_flags
alias setup='dir=$(mktemp -d) || return'
alias teardown='rm -rf $dir'

it 'emits an exclude flag for every default pattern'
result=$(exclude_flags)
assert equal ${#DEFAULT_EXCLUDES[@]} $(wc -l <<< "$result")
assert equal '--exclude=node_modules' "$(grep -x -- '--exclude=node_modules' <<< "$result")"
ti

it 'appends patterns read from the ignore file'
printf '%s\n' '# a comment' '' 'coverage' 'tmp/*' > $dir/ignore
result=$(exclude_flags $dir/ignore)
assert equal $'--exclude=coverage\n--exclude=tmp/*' "$(tail -2 <<< "$result")"
assert equal $((${#DEFAULT_EXCLUDES[@]} + 2)) $(wc -l <<< "$result")
ti

it 'ignores a missing ignore file'
result=$(exclude_flags $dir/nonexistent)
assert equal ${#DEFAULT_EXCLUDES[@]} $(wc -l <<< "$result")
ti
end_describe
end_describe
