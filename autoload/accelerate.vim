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
let s:last_accelerated_at = [0, 0]
let s:last_accelerated_key = 0

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_')
endfunction
let s:SID = "\<SNR>" . s:SID() . '_'

let g:accelerate_timeoutlen = get(g:, 'accelerate_timeoutlen', 80)
let g:accelerate_timeoutlens = get(g:, 'accelerate_timeoutlens', {})
let g:accelerate_velocity = get(g:, 'accelerate_velocity', 20)
let g:accelerate_duration = get(g:, 'accelerate_duration', 40)
let g:accelerate_easing = get(g:, 'accelerate_easing', 'accelerate#_easing')




" Interface  "{{{1
function! accelerate#map(modes, options, lhs, ...)  "{{{2
  let _ = {
  \   'velocity': g:accelerate_velocity,
  \   'duration': g:accelerate_duration,
  \   'easing': g:accelerate_easing,
  \ }

  if a:0 > 0
    let rhs = a:1
    call extend(_, get(a:000, 1, {}))
  else
    let rhs = a:lhs
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




function! accelerate#_easing(t, b, c, d)  "{{{2
  return a:c * min([a:t, a:d]) / a:d + a:b
endfunction




" Misc.  "{{{1
function! s:elapsed_time_in_milliseconds(now)  "{{{2
  return str2float(reltimestr(reltime(s:last_accelerated_at, a:now))) * 1000
endfunction




function! s:do_map(mode, options, lhs, rhs, velocity, duration, easing)  "{{{2
  let opt_buffer = a:options =~# 'b' ? '<buffer>' : ''
  let remap_p = a:options =~# 'r'

  execute printf('%smap <expr> %s %s  <SID>on_progress(%s, %d, %d, %s)',
  \              a:mode,
  \              opt_buffer,
  \              a:lhs,
  \              string(s:unescape_lhs(a:lhs)),
  \              a:velocity,
  \              a:duration,
  \              string(a:easing))
  execute printf('%s%smap %s <SID>rhs:%s  %s',
  \              a:mode,
  \              remap_p ? '' : 'nore',
  \              s:to_map_arguments(a:options),
  \              a:lhs,
  \              a:rhs)
endfunction




function! s:do_unmap(mode, options, lhs)  "{{{2
  let opt_buffer = a:options =~# 'b' ? '<buffer>' : ''

  execute printf('%sunmap %s %s',
  \              a:mode, opt_buffer, a:lhs)
  execute printf('%sunmap %s <SID>rhs:%s',
  \              a:mode, opt_buffer, a:lhs)
endfunction




function! s:each_char(s)  "{{{2
  return split(a:s, '.\zs')
endfunction




function! s:on_progress(lhs, velocity, duration, easing)  "{{{2
  if s:last_accelerated_key isnot a:lhs
  \  || s:elapsed_time_in_milliseconds(reltime())
  \     > get(g:accelerate_timeoutlens, a:lhs, g:accelerate_timeoutlen)
    let s:last_accelerated_key = a:lhs
    let s:count = 0
  endif
  let c = {a:easing}(s:count, 1, a:velocity, a:duration)
  let s:count += 1
  let s:last_accelerated_at = reltime()
  return c . s:SID . 'rhs:' . a:lhs
endfunction




function! s:split_to_keys(lhs)  "{{{2
  return split(a:lhs, '\(<[^<>]\+>\|.\)\zs')
endfunction




function! s:to_map_arguments(options)  "{{{2
  let _ = {'b': '<buffer>', 'e': '<expr>', 's': '<silent>', 'u': '<unique>'}
  return join(map(s:each_char(a:options), 'get(_, v:val, "")'))
endfunction




function! s:unescape_lhs(escaped_lhs)  "{{{2
  let keys = s:split_to_keys(a:escaped_lhs)
  call map(keys, 'v:val =~ "^<.*>$" ? eval(''"\'' . v:val . ''"'') : v:val')
  return join(keys, '')
endfunction




" __END__  "{{{1
" vim: foldmethod=marker
