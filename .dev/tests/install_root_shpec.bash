RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_utils.bash"
source "$RootDir/../install-root.bash"

describe 'install-root'
  alias setup='dir=$(mktemp -d) || return; src=$dir/root; dst=$dir/target; manifest=$dir/manifest
    mkdir -p $src/etc/app.d $dst/etc; printf a > $src/etc/a.conf; printf b > $src/etc/app.d/b.conf
    chmod 0755 $src/etc/app.d/b.conf'
  alias teardown='rm -rf $dir'

  it 'copies every package file with its mode'
    main $src $dst $manifest > /dev/null
    result=$(cat $dst/etc/a.conf $dst/etc/app.d/b.conf; stat -c %a $dst/etc/app.d/b.conf)
    assert equal 'ab755' "$result"
  ti

  it 'changes nothing on a second run'
    main $src $dst $manifest > /dev/null
    result=$(main $src $dst $manifest)
    assert equal 'root: every file is current' "$result"
  ti

  it 'replaces stow links into the package, including one whose target no longer exists'
    mkdir -p $dst/var/spool
    ln -s $src/etc/app.d $dst/etc/app.d
    ln -s $src/var/spool/cron $dst/var/spool/cron
    main $src $dst $manifest > /dev/null
    result=$([[ -d $dst/etc/app.d && ! -L $dst/etc/app.d ]] && echo dir; [[ -e $dst/var/spool/cron || -L $dst/var/spool/cron ]] || echo gone)
    assert equal $'dir\ngone' "$result"
  ti

  it 'removes an installed file that the package no longer has, and keeps files it never installed'
    printf own > $dst/etc/own.conf
    main $src $dst $manifest > /dev/null
    rm $src/etc/a.conf
    main $src $dst $manifest > /dev/null
    result=$([[ -e $dst/etc/a.conf ]] || echo removed; cat $dst/etc/own.conf)
    assert equal $'removed\nown' "$result"
  ti

  it 'rewrites a copy that differs from the package file'
    main $src $dst $manifest > /dev/null
    printf edited > $dst/etc/a.conf
    main $src $dst $manifest > /dev/null
    assert equal 'a' "$(cat $dst/etc/a.conf)"
  ti

  it 'exits nonzero without a source'
    (main) 2> /dev/null
    assert equal 1 $?
  ti
end_describe
