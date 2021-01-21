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
  let Contents = s:Contents.new({
        \ 'curr_lnum': self.curr_lnum,
        \ 'corr_lnum': self.corr_lnum,
        \ 'is_reverse': self.is_reverse,
        \ })
  let self.raw_text = Contents.Read()
  let self.text = self.truncate_as_fillable_width()
  return self.text
endfunction
let s:Text.set = funcref('s:Text__set')

function! s:Text__truncate_as_fillable_width() abort dict
  const max_column_width = s:get_config('max_column_width')
  const line = getline(self.curr_lnum)
  const fillable_width = max_column_width - strdisplaywidth(line)

  const ellipsis = g:doppelganger#text#ellipsis
  const len_ellipsis = strdisplaywidth(ellipsis)

  let text = ''
  let len = len_ellipsis
  for char in split(self.raw_text, '\zs')
    let len += strdisplaywidth(char)
    if len >= fillable_width
      let text .= ellipsis
      break
    endif
    let text .= char
  endfor

  return text
endfunction
let s:Text.truncate_as_fillable_width = funcref('s:Text__truncate_as_fillable_width')


let s:Contents = {}

function! s:Contents.new(dict) abort dict
  let Contents = deepcopy(s:Contents)
  let Contents.curr_lnum = a:dict.curr_lnum
  let Contents.corr_lnum = a:dict.corr_lnum
  let Contents.is_reverse = a:dict.is_reverse
  return Contents
endfunction

function! s:Contents__Read() abort dict
  call self.read_in_pair()
  call self.trim_whitespaces()
  call self.join()
  return self.text
endfunction
let s:Contents.Read = funcref('s:Contents__Read')

function! s:Contents__read_in_pair() abort dict
  let curr_lnum = self.curr_lnum
  let corr_lnum = self.corr_lnum

  if self.is_reverse
    let self.raw_contents = [getline(corr_lnum)]
    return
  endif

  const start = corr_lnum
  const end = curr_lnum - 1
  let self.raw_contents = getline(start, end)
endfunction
let s:Contents.read_in_pair = funcref('s:Contents__read_in_pair')

function! s:Contents__trim_whitespaces() abort dict
  let contents = map(deepcopy(self.raw_contents),
        \ 'substitute(v:val, ''^\s*\|\s*$'', "", "")')

  const compress_whitespaces = s:get_config('compress_whitespaces')
  if compress_whitespaces
    call map(contents, 'substitute(v:val, ''\s\{2,}'', " ", "g")')
  endif

  let self.contents = contents
endfunction
let s:Contents.trim_whitespaces = funcref('s:Contents__trim_whitespaces')

function! s:Contents__join() abort dict
  const prefix = s:get_config('prefix')
  const shim = s:get_config('shim_to_join')
  let text = prefix . join(self.contents, shim)
  let self.text = text
endfunction
let s:Contents.join = funcref('s:Contents__join')
