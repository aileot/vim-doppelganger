let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Text = {}
function! doppelganger#text#new(pair_info) abort
  let Text = deepcopy(s:Text)
  " TODO: make `Text` independent from pair_info.
  let Text = extend(Text, a:pair_info)
  return Text
endfunction

function! s:Text__SetVirtualtext() abort dict
  const text = self.set()
  if text ==# '' | return | endif

  let chunks = [[text, self.hl_group]]
  let print_lnum = self.curr_lnum - 1
  call nvim_buf_set_virtual_text(
        \ 0,
        \ g:__doppelganger_namespace,
        \ print_lnum,
        \ chunks,
        \ {}
        \ )
endfunction
let s:Text.SetVirtualtext = funcref('s:Text__SetVirtualtext')

function! s:Text__set() abort dict
  let Contents = s:Contents.new({
        \ 'curr_lnum': self.curr_lnum,
        \ 'corr_lnum': self.lnum,
        \ 'is_reverse': self.reverse,
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

function! s:Contents__truncate_to_join() abort dict
  let self.contents = map(deepcopy(self.raw_contents),
        \ 'substitute(v:val, ''^\s*\|\s*$'', "", "")')
endfunction
let s:Contents.truncate_to_join = funcref('s:Contents__truncate_to_join')

function! s:Contents__join() abort dict
  const prefix = s:get_config('prefix')
  const shim = s:get_config('shim_to_join')

  call self.truncate_to_join()
  let text = prefix . join(self.contents, shim)

  const compress_whitespaces = s:get_config('compress_whitespaces')
  if compress_whitespaces
    let text = substitute(text, '\s\{2,}', ' ', 'g')
  endif

  let self.text = text
endfunction
let s:Contents.join = funcref('s:Contents__join')
