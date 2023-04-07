function! LinerEasing(t, b, c, d)
  return a:t + a:b
endfunction

function! s:before() abort
  new

  call accelerate#map('nv', 'b', 'j', 'j', {
  \   'beginning_value': 1,
  \   'change_in_value': 10,
  \   'duration': 20,
  \   'timeout': 10,
  \   'easing': 'LinerEasing'
  \ })
  call accelerate#map('nv', 'b', 'k', 'k', {
  \   'beginning_value': 1,
  \   'change_in_value': 10,
  \   'duration': 20,
  \   'timeout': 10,
  \   'easing': 'LinerEasing'
  \ })
endfunction

function! s:after() abort
  bdelete!
endfunction

function! s:test_mapping() abort
  call s:before()

  try
    let SID = matchstr(maparg('j', 'n'), '<SNR>\d\+_')
    call assert_notequal('', SID)

    for mode in ['n', 'v']
      call assert_match('\V'. SID . "on_progress('j', 1, 10, 20, 10, 'LinerEasing')", maparg('j', mode))
      call assert_equal('j', maparg(SID . 'rhs:j', mode))

      call assert_match('\V' . SID . "on_progress('k', 1, 10, 20, 10, 'LinerEasing')", maparg('k', mode), )
      call assert_equal('k', maparg(SID . 'rhs:k', mode))
    endfor

    call accelerate#unmap('nv', 'b', 'j')
    call accelerate#unmap('nv', 'b', 'k')

    for mode in ['n', 'v']
      call assert_equal(maparg('j', mode), '')
      call assert_equal(maparg(SID . 'rhs:j', mode), '')
      call assert_equal(maparg('k', mode), '')
      call assert_equal(maparg(SID . 'rhs:k', mode), '')
    endfor
  finally
    call s:after()
  endtry
endfunction

function! s:test_cursor_moving() abort
  call s:before()

  try
    silent put =range(1, 100)
    1 delete _

    normal ggj
    call assert_equal(1 + 1, line('.'))

    sleep 10m

    normal ggjj
    call assert_equal(line('.'), 1 + 1 + 2)

    sleep 10m

    normal ggjjj
    call assert_equal(line('.'), 1 + 1 + 2 + 3)

    sleep 10m

    normal ggjjjj
    call assert_equal(line('.'), 1 + 1 + 2 + 3 + 4)

    sleep 10m

    normal ggjjjjj
    call assert_equal(line('.'), 1 + 1 + 2 + 3 + 4 + 5)

    sleep 15m

    normal ggj
    call assert_equal(line('.'), 1 + 1)

    sleep 10m

    normal ggjjjjj
    call assert_equal(line('.'), 1 + 1 + 2 + 3 + 4 + 5)

    normal Gkkkkk
    call assert_equal(line('.'), 100 - 1 - 2 - 3 - 4 - 5)
  finally
    call s:after()
  endtry
endfunction
