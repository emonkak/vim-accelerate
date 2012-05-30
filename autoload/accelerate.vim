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
" Global  "{{{2

let g:accelerate_timeoutlen = get(g:, 'accelerate_timeoutlen', 40)
let g:accelerate_timeoutlens = get(g:, 'accelerate_timeoutlens', {})
let g:accelerate_velocity = get(g:, 'accelerate_velocity', 10)
let g:accelerate_duration = get(g:, 'accelerate_duration', 20)
let g:accelerate_easing = get(g:, 'accelerate_easing', "\<SID>easing")




" Script-local  "{{{2

let s:count = 0




" Interface  "{{{1
function! accelerate#map(modes, options, lhs, rhs, ...)  "{{{2
  let _ = {
  \   'velocity': g:accelerate_velocity,
  \   'duration': g:accelerate_duration,
  \   'easing':  g:accelerate_easing,
  \ }
  if a:0 > 0
    call extend(_, a:1)
  endif

  for mode in s:each_char(a:modes)
    call s:do_map(mode, a:options, a:lhs, a:rhs, _.velocity, _.duration, _.easing)
  endfor
  return
endfunction




function! s:on_end(lhs)  "{{{2
  call s:restore_options()
  return printf("\<Plug>(accelerate-rhs:%s)", a:lhs)
endfunction




function! s:on_start(lhs)  "{{{2
  if s:count is 0
    call s:set_up_options(a:lhs)
  endif
  return printf("\<Plug>(accelerate-prefix:%s)", a:lhs)
endfunction




function! s:on_progress(lhs, velocity, duration, easing)  "{{{2
  let rhs = printf("\<Plug>(accelerate-rhs:%s)", a:lhs)
  let c = {a:easing}(s:count, 1, a:velocity, a:duration)
  call feedkeys(c . rhs . printf("\<Plug>(accelerate-prefix:%s)", a:lhs), 't')
  let s:count += 1
  return ''
endfunction




function! s:do_map(mode, options, lhs, rhs, velocity, duration, easing)  "{{{2
  let opt_buffer = a:options =~# 'b' ? '<buffer>' : ''
  let opt_expr = a:options =~# 'e' ? '<expr>' : ''
  let remap_p = a:options =~# 'r'
  let last_key = a:lhs[strlen(a:lhs) - 1]

  execute printf('%smap <expr> %s %s  <SID>on_start(%s)',
  \              a:mode, opt_buffer, a:lhs, string(a:lhs))
  execute printf('%smap <expr> <Plug>(accelerate-prefix:%s)  <SID>on_end(%s)',
  \              a:mode, a:lhs, string(a:lhs))
  execute printf('%smap <expr> <Plug>(accelerate-prefix:%s)%s  <SID>on_progress(%s, %d, %d, %s)',
  \              a:mode,
  \              a:lhs,
  \              last_key,
  \              string(a:lhs),
  \              a:velocity,
  \              a:duration,
  \              string(a:easing))
  execute printf('%s%smap %s <Plug>(accelerate-rhs:%s)  %s',
  \              a:mode,
  \              remap_p ? '' : 'nore',
  \              opt_expr,
  \              a:lhs,
  \              a:rhs)
endfunction




" Misc.  "{{{1
function! s:easing(t, b, c, d)  "{{{2
  let t = (a:t + 0.0) / (a:d + 0.0)
  return float2nr(round(a:c * t * t * t + a:b))
endfunction




function! s:each_char(s)  "{{{2
  return split(a:s, '.\zs')
endfunction




function! s:restore_options()  "{{{2
  let s:count = 0

  let &showcmd = s:original_showcmd
  let &timeout = s:original_timeout
  let &timeoutlen = s:original_timeoutlen
  let &ttimeoutlen = s:original_ttimeoutlen
endfunction




function! s:set_up_options(key)  "{{{2
  let s:original_showcmd = &showcmd
  let s:original_timeout = &timeout
  let s:original_timeoutlen = &timeoutlen
  let s:original_ttimeoutlen = &ttimeoutlen

  set noshowcmd  " To avoid flickering in the bottom line.
  set timeout  " To ensure time out on :mappings
  let &timeoutlen = get(g:accelerate_timeoutlens,
  \                     a:key,
  \                     g:accelerate_timeoutlen)
  let &ttimeoutlen = (0 <= s:original_ttimeoutlen
  \                   ? s:original_ttimeoutlen
  \                   : s:original_timeoutlen)
endfunction




" __END__  "{{{1
" vim: foldmethod=marker
