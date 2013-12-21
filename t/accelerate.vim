runtime! autoload/accelerate.vim

function! LinerEasing(t, b, c, d)
  return a:t + a:b
endfunction

describe 'accelerate#map'
  before
    new
    put =range(1, 100)
    1 delete _
    call accelerate#map('nv', 'b', 'j', 'gj', {
    \ 'beginning_value': 1,
    \ 'change_in_value': 10,
    \ 'duration': 20,
    \ 'timeout': 100,
    \ 'easing': 'LinerEasing'
    \ })
    call accelerate#map('nv', 'b', 'k', 'gk', {
    \ 'beginning_value': 1,
    \ 'change_in_value': 10,
    \ 'duration': 20,
    \ 'timeout': 100,
    \ 'easing': 'LinerEasing'
    \ })
  end

  after
    quit!
  end

  it 'defines a key mapping properly'
    for mode in ['n', 'v']
      let SID = matchstr(maparg('j', mode), '<SNR>\d\+_')
      Expect SID != ''

      Expect stridx(maparg('j', mode), SID . "on_progress('j', 1, 10, 20, 100, 'LinerEasing')") > -1
      Expect maparg(SID . 'rhs:j', mode) ==# 'gj'

      let SID = matchstr(maparg('k', mode), '<SNR>\d\+_')
      Expect SID != ''

      Expect stridx(maparg('k', mode), SID . "on_progress('k', 1, 10, 20, 100, 'LinerEasing')") > -1
      Expect maparg(SID . 'rhs:k', mode) ==# 'gk'
    endfor
  end

  it 'is mapped to work properly'
    let g:accelerate_timeoutlens = {'j': 100, 'g': 100}

    Expect line('.') == 1

    normal ggj
    Expect line('.') == 1 + 1

    sleep 100m

    normal ggjj
    Expect line('.') == 1 + 1 + 2

    sleep 100m

    normal ggjjj
    Expect line('.') == 1 + 1 + 2 + 3

    sleep 100m

    normal ggjjjj
    Expect line('.') == 1 + 1 + 2 + 3 + 4

    sleep 100m

    normal ggjjjjj
    Expect line('.') == 1 + 1 + 2 + 3 + 4 + 5

    sleep 150m

    normal ggj
    Expect line('.') == 1 + 1

    sleep 100m

    normal ggjjjjj
    Expect line('.') == 1 + 1 + 2 + 3 + 4 + 5

    normal Gkkkkk
    Expect line('.') == line('$') - 1 - 2 - 3 - 4 - 5
  end
end

describe 'accelerate#unmap'
  it 'undefines a key mapping properly'
    call accelerate#map('nv', '', 'j', 'gk')

    let SID = matchstr(maparg('j', 'n'), '<SNR>\d\+_')
    Expect SID != ''

    call accelerate#unmap('nv', '', 'j')

    for mode in ['n', 'v']
      Expect maparg('j', mode) == ''
      Expect maparg(SID . 'rhs:j', mode) == ''
    endfor
  end
end
