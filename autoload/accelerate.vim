" accelerate - plunge into accel world
" Version: 0.0.0
" Copyright (C) 2012 emonkak <emonkak@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" Variables  "{{{1

let s:count = 0

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_')
endfunction
let s:SID = "\<SNR>" . s:SID() . '_'

let g:accelerate_timeoutlen = get(g:, 'accelerate_timeoutlen', 80)
let g:accelerate_timeoutlens = get(g:, 'accelerate_timeoutlens', {})
let g:accelerate_velocity = get(g:, 'accelerate_velocity', 20)
let g:accelerate_duration = get(g:, 'accelerate_duration', 40)
let g:accelerate_easing = get(g:, 'accelerate_easing', s:SID . 'easing')




" Interface  "{{{1
function! accelerate#map(modes, options, lhs, ...)  "{{{2
  let _ = {
  \   'velocity': g:accelerate_velocity,
  \   'duration': g:accelerate_duration,
  \   'easing': g:accelerate_easing,
  \ }
  let rhs = get(a:000, 0, a:lhs)

  if type(rhs) == type({})
    call extend(_, rhs)
    let rhs = a:lhs
  else
    call extend(_, get(a:000, 1, {}))
  endif

  for mode in s:each_char(a:modes)
    call s:do_map(mode, a:options, a:lhs, rhs, _.velocity, _.duration, _.easing)
  endfor
endfunction




function! accelerate#unmap(modes, options, lhs)  "{{{2
  for mode in s:each_char(a:modes)
    call s:do_unmap(mode, a:options, a:lhs)
  endfor
endfunction




function! s:on_end(lhs)  "{{{2
  call s:restore_options()
  return s:SID . 'rhs:' . a:lhs
endfunction




function! s:on_start(lhs)  "{{{2
  if s:count is 0
    call s:set_up_options(a:lhs)
  endif
  return s:SID . 'prefix:' . a:lhs
endfunction




function! s:on_progress(lhs, velocity, duration, easing)  "{{{2
  let c = function(a:easing)(s:count, 1, a:velocity, a:duration)
  let rhs = s:SID . 'rhs:' . a:lhs
  let prefix = s:SID . 'prefix:' . a:lhs
  call feedkeys(c . rhs . prefix, 't')
  let s:count += 1
  return ''
endfunction




function! s:do_map(mode, options, lhs, rhs, velocity, duration, easing)  "{{{2
  let opt_buffer = a:options =~# 'b' ? '<buffer>' : ''
  let remap_p = a:options =~# 'r'
  let last_key = s:last_key(a:lhs)

  execute printf('%smap <expr> %s %s  <SID>on_start(%s)',
  \              a:mode, opt_buffer, a:lhs, string(a:lhs))
  execute printf('%smap <expr> %s <SID>prefix:%s  <SID>on_end(%s)',
  \              a:mode, opt_buffer, a:lhs, string(a:lhs))
  execute printf('%smap <expr> %s <SID>prefix:%s%s  <SID>on_progress(%s, %d, %d, %s)',
  \              a:mode,
  \              opt_buffer,
  \              a:lhs,
  \              last_key,
  \              string(a:lhs),
  \              a:velocity,
  \              a:duration,
  \              string(a:easing))
  execute printf('%s%smap %s <SID>rhs:%s  %s',
  \              a:mode,
  \              remap_p ? '' : 'nore',
  \              s:map_options(a:options),
  \              a:lhs,
  \              a:rhs)
endfunction




function! s:do_unmap(mode, options, lhs)  "{{{2
  let opt_buffer = a:options =~# 'b' ? '<buffer>' : ''
  let last_key = s:last_key(a:lhs)

  execute printf('%sunmap %s %s',
  \              a:mode, opt_buffer, a:lhs)
  execute printf('%sunmap %s <SID>prefix:%s',
  \              a:mode, opt_buffer, a:lhs)
  execute printf('%sunmap %s <SID>prefix:%s%s',
  \              a:mode, opt_buffer, a:lhs, last_key)
  execute printf('%sunmap %s <SID>rhs:%s',
  \              a:mode, opt_buffer, a:lhs)
endfunction




" Misc.  "{{{1
function! s:easing(t, b, c, d)  "{{{2
  return a:c * min([a:t, a:d]) / a:d + a:b
endfunction




function! s:each_char(s)  "{{{2
  return split(a:s, '.\zs')
endfunction




function! s:restore_options()  "{{{2
  let s:count = 0

  let &eventignore = s:original_eventignore
  let &showcmd = s:original_showcmd
  let &timeout = s:original_timeout
  let &timeoutlen = s:original_timeoutlen
  let &ttimeoutlen = s:original_ttimeoutlen
endfunction




function! s:set_up_options(lhs)  "{{{2
  let s:original_eventignore = &eventignore
  let s:original_showcmd = &showcmd
  let s:original_timeout = &timeout
  let s:original_timeoutlen = &timeoutlen
  let s:original_ttimeoutlen = &ttimeoutlen

  set eventignore+=CursorMoved,CursorMovedI
  set noshowcmd  " To avoid flickering in the bottom line.
  set timeout  " To ensure time out on :mappings
  let &timeoutlen = get(g:accelerate_timeoutlens,
  \                     a:lhs,
  \                     g:accelerate_timeoutlen)
  let &ttimeoutlen = s:original_ttimeoutlen < 0
  \                ? s:original_timeoutlen
  \                : s:original_ttimeoutlen
endfunction




function! s:map_options(options)  "{{{2
  let _ = {
  \   'b': '<buffer>',
  \   'e': '<expr>',
  \   's': '<silent>',
  \   'u': '<unique>',
  \ }
  return join(map(s:each_char(a:options), 'get(_, v:val, "")'))
endfunction




function! s:last_key(key)  "{{{2
  return matchstr(a:key, '\(<[0-9A-Za-z-]\+>\|\S\)$')
endfunction




" __END__  "{{{1
" vim: foldmethod=marker
