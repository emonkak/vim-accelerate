if !exists('g:accelerate_debug')
  let g:accelerate_debug = 0
endif

function! s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
let s:SID = "\<SNR>" . s:SID() . '_'

let s:repeated_count = 0
let s:last_accelerated_time = 0
let s:last_key = 0

function! accelerate#map(modes, options, lhs, ...) abort
  let acceleration_spec = {
  \   'min_count': 0,
  \   'max_count': 50,
  \   'acceleration_steps': 100,
  \   'easing_func': s:SID . 'ease_linear',
  \   'timeout': 100,
  \ }

  let rhs = a:0 > 0 ? a:1 : a:lhs

  if a:0 > 1
    call extend(acceleration_spec, a:2)
  endif

  for mode in s:each_char(a:modes)
    call s:define_mappings(mode, a:options, a:lhs, rhs, acceleration_spec)
  endfor
endfunction

function! accelerate#unmap(modes, options, lhs) abort
  for mode in s:each_char(a:modes)
    call s:remove_mappings(mode, a:options, a:lhs)
  endfor
endfunction

function! s:define_mappings(mode, options, lhs, rhs, acceleration_spec) abort
  let buffer_local = a:options =~# 'b' ? '<buffer>' : ''
  let no_remap = a:options =~# 'r' ? '' : 'nore'

  execute printf('%snoremap <script> <expr> %s %s v:count ? %s : <SID>on_step(%s, %d, %d, %d, %s, %d)',
  \              a:mode,
  \              buffer_local,
  \              a:lhs,
  \              string('<SID>rhs:' . a:lhs),
  \              string(s:unescape_key_sequence(a:lhs)),
  \              a:acceleration_spec.min_count,
  \              a:acceleration_spec.max_count,
  \              a:acceleration_spec.acceleration_steps,
  \              string(a:acceleration_spec.easing_func),
  \              a:acceleration_spec.timeout)
  execute printf('%s%smap %s <SID>rhs:%s %s',
  \              a:mode,
  \              no_remap,
  \              s:expand_map_arguments(a:options),
  \              a:lhs,
  \              a:rhs)
endfunction

function! s:each_char(s) abort
  return split(a:s, '.\zs')
endfunction

function! s:ease_linear(t) abort
  return a:t
endfunction

function! s:elapsed_millis(start_time, end_time) abort
  return reltimefloat(reltime(a:start_time, a:end_time)) * 1000
endfunction

function! s:expand_map_arguments(arguments) abort
  let _ = {'b': '<buffer>', 'e': '<expr>', 's': '<silent>', 'u': '<unique>'}
  return join(map(s:each_char(a:arguments), 'get(_, v:val, "")'))
endfunction

function! s:on_step(lhs, min_count, max_count, acceleration_steps, easing_func, timeout) abort
  let current_time = reltime()

  if s:last_key is a:lhs
    let elapsed_millis = s:elapsed_millis(s:last_accelerated_time, current_time)
    if elapsed_millis > a:timeout
      let s:repeated_count = 0
    endif
  else
    let s:last_key = a:lhs
    let s:repeated_count = 0
  endif

  let acceleration = s:repeated_count < a:acceleration_steps
  \                ? s:repeated_count / (a:acceleration_steps * 1.0)
  \                : 1.0
  let acceleration = {a:easing_func}(acceleration)
  let l:count = a:min_count + (acceleration * (a:max_count - a:min_count))
  let l:count = float2nr(round(l:count))
  let l:count = l:count > 1 ? l:count : ''

  if g:accelerate_debug
    " 20 = 2(spaces) + 4(percent) + 12(reserved area) + 2(progress bracket)
    let count_len = float2nr(log10(a:max_count) + 1)
    let progress_len = &columns - (count_len + 20)
    if progress_len > 0
      let progress_value = float2nr(round(progress * progress_len))
      let progress_bar = repeat('#', progress_value)
      \                . repeat('.', progress_len - progress_value)
      echo printf('%*d [%s] %3d%%',
      \           count_len,
      \           l:count,
      \           progress_bar,
      \           float2nr(round(progress * 100)))
    endif
  endif

  let s:repeated_count += 1
  let s:last_accelerated_time = current_time

  return l:count . s:SID . 'rhs:' . a:lhs
endfunction

function! s:remove_mappings(mode, options, lhs) abort
  let buffer_local = a:options =~# 'b' ? '<buffer>' : ''

  execute printf('%sunmap %s %s', a:mode, buffer_local, a:lhs)
  execute printf('%sunmap %s <SID>rhs:%s', a:mode, buffer_local, a:lhs)
endfunction

function! s:split_to_keys(key_sequence) abort
  return split(a:key_sequence, '\(<[^<>]\+>\|.\)\zs')
endfunction

function! s:unescape_key(key) abort
  if a:key =~# '^<\a[0-9A-Za-z_-]*>$'
    let unescaped_key = eval('"\' . a:key . '"')
    return unescaped_key ==# '|' ? '<Bar>' : unescaped_key
  endif
  return a:key
endfunction

function! s:unescape_key_sequence(key_sequence) abort
  let keys = s:split_to_keys(a:key_sequence)
  return join(map(keys, 's:unescape_key(v:val)'), '')
endfunction
