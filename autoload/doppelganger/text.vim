let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Text = {}
function! doppelganger#text#new(pair_info) abort
  let s:Text = extend(s:Text, a:pair_info)
  let text_info = deepcopy(s:Text)
  return text_info
endfunction

function! s:Text.SetVirtualText() abort dict
  const text = self._Set()
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

function! s:Text._Set() abort dict
  let self.raw_text = self._Join_contents()
  let self.text = self._Truncate_as_fillable_width()
  return self.text
endfunction

function! s:Text._Join_contents() abort dict
  const prefix = s:get_config('prefix')
  const shim = s:get_config('shim_to_join')

  let contents = self._Read_contents_in_pair()
  let contents = self._Trancate_contents_to_join()

  let text = prefix . join(contents, shim)

  const compress_whitespaces = s:get_config('compress_whitespaces')
  if compress_whitespaces
    let text = substitute(text, '\s\{2,}', ' ', 'g')
  endif
  return text
endfunction

function! s:Text._Read_contents_in_pair() abort dict
  let self.contents = []

  if self.reverse
    let self.contents = [getline(self.corr_lnum)]
    return self.contents
  endif

  const start = self.corr_lnum
  const end = self.curr_lnum - 1
  let self.contents = getline(start, end)

  return self.contents
endfunction

function! s:Text._Trancate_contents_to_join() abort dict
  let contents = self.contents
  let self.contents = map(contents, 'substitute(v:val, ''^\s*\|\s*$'', "", "")')
  return self.contents
endfunction

function! s:Text._Truncate_as_fillable_width() abort dict
  const max_column_width = s:get_config('max_column_width')
  const line = getline(self.curr_lnum)
  const fillable_width = max_column_width - strdisplaywidth(line)

  let len = 0
  let text = ''
  for char in split(self.raw_text, '\zs')
    let len += strdisplaywidth(char)
    if len >= fillable_width | break | endif
    let text .= char
  endfor

  let self.text = text
  return text
endfunction

