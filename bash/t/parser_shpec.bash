RootDir="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$RootDir/../../.test/shpec_util.bash"
source "$RootDir/../.config/bash/lib/parser.bash"


describe 'parseopts'
  it 'returns a short flag'
    defs=( -o,o_flag,f  )
    args=( -o           )
    parser::parseopts "${args[*]}" "${defs[*]}" options posargs
    assert equal o_flag=1 $options
  ti

  it "returns with _err_=1 if the argument isn't defined"
    defs=( -o,o_flag,f  )
    args=( --other      )
    parser::parseopts "${args[*]}" "${defs[*]}" options posargs
    assert equal 1 $_err_
  ti

  it 'returns a named argument'
    defs=( --option,option_val  )
    args=( --option sample      )
    parser::parseopts "${args[*]}" "${defs[*]}" options posargs
    assert equal option_val=sample $options
  ti

  it 'returns a named argument and a flag'
    defs=(
      --option,option_val
      -p,p_flag,f
    )
    args=( --option sample -p )
    parser::parseopts "${args[*]}" "${defs[*]}" options posargs
    expecteds=(
      option_val=sample
      p_flag=1
    )
    assert equal "${expecteds[*]}" "${options[*]}"
  ti

  it 'stops when it encounters a non-option'
    defs=( --option,option_val  )
    args=( --option sample -    )
    parser::parseopts "${args[*]}" "${defs[*]}" options posargs
    assert equal option_val=sample $options
  ti

  it 'stops when it encounters --'
    defs=(
      --option,option_val
      -p,p_flag,f
    )
    args=( --option sample -- -p )
    parser::parseopts "${args[*]}" "${defs[*]}" options posargs
    assert equal option_val=sample $options
  ti

  it 'returns positional arguments'
    defs=( -o,o_flag,f  )
    args=( -o one two   )
    parser::parseopts "${args[*]}" "${defs[*]}" options posargs
    expecteds=( one two )
    assert equal "${expecteds[*]}" "${posargs[*]}"
  ti
end_describe
