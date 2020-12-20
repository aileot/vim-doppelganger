let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Text = {}
function! doppelganger#text#new(pair_info) abort
  let s:Text = extend(s:Text, a:pair_info)
  let text_info = deepcopy(s:Text)
  return text_info
endfunction

function! s:Text.SetVirtualtext() abort dict
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

function! s:Text__set() abort dict
  let self.raw_text = self.join_contents()
  let self.text = self.truncate_as_fillable_width()
  return self.text
endfunction
let s:Text.set = funcref('s:Text__set')

function! s:Text__join_contents() abort dict
  const prefix = s:get_config('prefix')
  const shim = s:get_config('shim_to_join')

  let contents = self.read_contents_in_pair()
  let contents = self.truncate_contents_to_join()

  let text = prefix . join(contents, shim)

  const compress_whitespaces = s:get_config('compress_whitespaces')
  if compress_whitespaces
    let text = substitute(text, '\s\{2,}', ' ', 'g')
  endif
  return text
endfunction
let s:Text.join_contents = funcref('s:Text__join_contents')

function! s:Text__read_contents_in_pair() abort dict
  let self.contents = []

  if self.reverse
    let self.contents = [getline(self.lnum)]
    return self.contents
  endif

  const start = self.lnum
  const end = self.curr_lnum - 1
  let self.contents = getline(start, end)

  return self.contents
endfunction
let s:Text.read_contents_in_pair = funcref('s:Text__read_contents_in_pair')

function! s:Text__truncate_contents_to_join() abort dict
  let contents = self.contents
  let self.contents = map(contents, 'substitute(v:val, ''^\s*\|\s*$'', "", "")')
  return self.contents
endfunction
let s:Text.truncate_contents_to_join = funcref('s:Text__truncate_contents_to_join')

function! s:Text__truncate_as_fillable_width() abort dict
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
let s:Text.truncate_as_fillable_width = funcref('s:Text__truncate_as_fillable_width')
