let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Text = {}
function! doppelganger#text#new(pair_info) abort
  let Text = deepcopy(s:Text)
  " TODO: make `Text` independent from pair_info.
  let Text = extend(Text, a:pair_info)
  return Text
endfunction

function! s:Text__get_chunks() abort dict
  " It's used esp. for cached instances.
  return get(self, 'chunks', v:null)
endfunction
let s:Text.get_chunks = funcref('s:Text__get_chunks')

function! s:Text__SetHlGroup(hl_group) abort dict
  let self.hl_group = a:hl_group
endfunction
let s:Text.SetHlGroup = funcref('s:Text__SetHlGroup')

function! s:Text__ComposeChunks() abort dict
  const text = self.set()
  if text ==# '' | return | endif
  let chunks = [[text, self.hl_group]]
  return chunks
endfunction
let s:Text.ComposeChunks = funcref('s:Text__ComposeChunks')

function! s:Text__set() abort dict
  let Contents = self.is_reverse
        \ ? doppelganger#text#contents#new(self.corr_lnum)
        \ : doppelganger#text#contents#new(self.corr_lnum, self.curr_lnum)
  let self.raw_text = Contents.Read()
  let self.text = self.truncate_as_fillable_width()
  return self.text
endfunction
let s:Text.set = funcref('s:Text__set')

function! s:Text__replace_keywords(text) abort dict
  const abs = self.corr_lnum
  const rel = abs(self.curr_lnum - self.corr_lnum)
  const size = rel + 1

  let text = a:text
  let text = substitute(text, '<absolute>', abs, 'g')
  let text = substitute(text, '<relative>', rel, 'g')
  let text = substitute(text, '<size>', size, 'g')
  return text
endfunction
let s:Text.replace_keywords = funcref('s:Text__replace_keywords')

function! s:Text__truncate_as_fillable_width() abort dict
  let prefix = s:get_config('prefix')
  let prefix = self.replace_keywords(prefix)
  let suffix = s:get_config('suffix')
  let suffix = self.replace_keywords(suffix)

  const line = getline(self.curr_lnum)
  " Add 1 for a space inserted before any virtual text starts.
  const len_reserved = strdisplaywidth(line . prefix . suffix) + 1
  const max_column_width = eval(s:get_config('max_column_width'))
  let fillable_width = max_column_width - len_reserved

  const ellipsis = g:doppelganger#text#ellipsis
  const len_ellipsis = strdisplaywidth(ellipsis)

  let text = ''
  let rest_width = fillable_width
  for char in split(self.raw_text, '\zs')
    let fillable_width -= strdisplaywidth(char)
    if fillable_width < len_ellipsis
      let rest_width -= len_ellipsis
      let text .= ellipsis
      break
    endif
    let rest_width = fillable_width
    let text .= char
  endfor

  if suffix isnot# '' && rest_width > 0
    let text .= repeat(' ', rest_width)
  endif

  let text = prefix . text . suffix
  return text
endfunction
let s:Text.truncate_as_fillable_width = funcref('s:Text__truncate_as_fillable_width')

