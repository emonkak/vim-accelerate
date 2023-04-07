function! s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
let s:SID = "\<SNR>" . s:SID() . '_'

function! s:before() abort
  new
  call accelerate#map('nv', 'b', 'j', 'j', {
  \   'min_count': 0,
  \   'max_count': 10,
  \   'acceleration_steps': 10,
  \   'timeout': 100,
  \ })
  call accelerate#map('nv', 'b', 'k', 'k', {
  \   'min_count': 0,
  \   'max_count': 10,
  \   'acceleration_steps': 10,
  \   'timeout': 100,
  \ })
endfunction

function! s:after() abort
  bdelete!
endfunction

function! s:test_cursor_down() abort
  call s:before()

  let INCREMENTS = [1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  try
    call setline(1, range(1, 100))

    for i in range(len(INCREMENTS))
      normal j
      call assert_equal(1 + s:sum(INCREMENTS[0:i]), line('.'))
    endfor

    sleep 100m

    normal j
    call assert_equal(1 + s:sum(INCREMENTS) + 1, line('.'))
  finally
    call s:after()
  endtry
endfunction

function! s:test_cursor_up() abort
  call s:before()

  let INCREMENTS = [1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  try
    call setline(1, range(1, 100))

    normal G

    for n in range(len(INCREMENTS))
      normal k
      call assert_equal(100 - s:sum(INCREMENTS[0:n]), line('.'))
    endfor

    sleep 100m

    normal k
    call assert_equal(100 - (s:sum(INCREMENTS) + 1), line('.'))
  finally
    call s:after()
  endtry
endfunction

function! s:sum(xs) abort
  let total = 0
  for x in a:xs
    let total += x
  endfor
  return total
endfunction
