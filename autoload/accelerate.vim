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
let s:last_accelerated_at = reltime()
let s:last_accelerated_key = 0

function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_')
endfunction
let s:SID = "\<SNR>" . s:SID() . '_'

let g:accelerate_timeout = get(g:, 'accelerate_timeout', 80)
let g:accelerate_beginning_value = get(g:, 'accelerate_beginning_value', 1)
let g:accelerate_change_in_value = get(g:, 'accelerate_change_in_value', 20)
let g:accelerate_duration = get(g:, 'accelerate_duration', 40)
let g:accelerate_easing = get(g:, 'accelerate_easing', 'accelerate#_liner_easing')




" Interface  "{{{1
function! accelerate#map(modes, options, lhs, ...)  "{{{2
  let _ = {
  \   'beginning_value': g:accelerate_beginning_value,
  \   'change_in_value': g:accelerate_change_in_value,
  \   'duration': g:accelerate_duration,
  \   'timeout': g:accelerate_timeout,
  \   'easing': g:accelerate_easing
  \ }

  if v:version < 703 || v:version == 703 && !has('patch86')
    echomsg 'accelerate.vim does not work this version of Vim. Please use 7.3.086 or later.'
    return
  endif

  let rhs = get(a:000, 0, a:lhs)
  call extend(_, get(a:000, 1, {}))

  for mode in s:each_char(a:modes)
    call s:do_map(mode, a:options, a:lhs, rhs, _)
  endfor
endfunction




function! accelerate#unmap(modes, options, lhs)  "{{{2
  for mode in s:each_char(a:modes)
    call s:do_unmap(mode, a:options, a:lhs)
  endfor
endfunction




function! accelerate#_liner_easing(t, b, c, d)  "{{{2
  " simple linear tweening
  " http://www.gizma.com/easing/
  return a:c * a:t / a:d + a:b
endfunction




" Misc.  "{{{1
function! s:elapsed_time_ms(start, end)  "{{{2
  return str2float(reltimestr(reltime(a:start, a:end))) * 1000
endfunction




function! s:do_map(mode, options, lhs, rhs, _)  "{{{2
  let opt_buffer = a:options =~# 'b' ? '<buffer>' : ''
  let remap_p = a:options =~# 'r'

  execute printf('%smap <expr> %s %s v:count ? %s : <SID>on_progress(%s, %d, %d, %d, %d, %s)',
  \              a:mode,
  \              opt_buffer,
  \              a:lhs,
  \              string(s:SID . 'rhs:' . a:lhs),
  \              string(s:unescape_lhs(a:lhs)),
  \              a:_.beginning_value,
  \              a:_.change_in_value,
  \              a:_.duration,
  \              a:_.timeout,
  \              string(a:_.easing))
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




function! s:on_progress(lhs, beginning_value, change_in_value, duration, timeout, easing)  "{{{2
  if s:last_accelerated_key is a:lhs
    if s:elapsed_time_ms(s:last_accelerated_at, reltime()) > a:timeout
      let s:count = 0
    endif
  else
    let s:count = 0
    let s:last_accelerated_key = a:lhs
  endif

  let c = {a:easing}(min([s:count, a:duration]),
  \                  a:beginning_value,
  \                  a:change_in_value,
  \                  a:duration)
  let c = float2nr(round(c))

  if exists('g:accelerate_debug_p') && g:accelerate_debug_p
    let upper_limit = a:beginning_value + a:change_in_value
    let number_of_digits = float2nr(log10(upper_limit) + 1)
    let progress = float2nr(1.0 * c / upper_limit * &columns)
    echomsg printf('%*d/%d %d %s',
    \              number_of_digits,
    \              c,
    \              upper_limit,
    \              s:count,
    \              repeat('|', progress - (number_of_digits * 2)))
  endif

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
