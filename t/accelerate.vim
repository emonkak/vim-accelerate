runtime! autoload/accelerate.vim

function! LinerEasing(t, b, c, d)
  return a:t
endfunction

describe 'accelerate#map'
  before
    new
    put =range(1, 100)
    1 delete _
    call accelerate#map('nv', 'b', 'j', 'gj', {'easing': 'LinerEasing'})
  end

  after
    quit!
  end

  it 'defines a key mapping properly'
    for mode in ['n', 'v']
      let SID = matchstr(maparg('j', mode), '<SNR>\d\+_')
      Expect maparg('j', mode) =~# 'on_progress'
      Expect maparg(SID . 'rhs:j', mode) ==# 'gj'
    endfor
  end

  it 'is mapped to work properly'
    let g:accelerate_timeoutlens = {'j': 100}

    Expect line('.') == 1

    normal ggj
    Expect line('.') == 1 + 1

    sleep 100m

    normal ggjj
    Expect line('.') == 1 + 1 + 1

    sleep 100m

    normal ggjjj
    Expect line('.') == 1 + 1 + 1 + 2

    sleep 100m

    normal ggjjjj
    Expect line('.') == 1 + 1 + 1 + 2 + 3

    sleep 100m

    normal ggjjjjj
    Expect line('.') == 1 + 1 + 1 + 2 + 3 + 4
  end
end

describe 'accelerate#unmap'
  it 'undefines a key mapping properly'
    call accelerate#map('nv', '', 'j', 'gk')
    call accelerate#unmap('nv', '', 'j')

    for mode in ['n', 'v']
      let SID = matchstr(maparg('j', mode), '<SNR>\d\+_')
      Expect maparg('j', mode) == ''
      Expect maparg(SID . 'rhs:j', mode) == ''
    endfor
  end
end
