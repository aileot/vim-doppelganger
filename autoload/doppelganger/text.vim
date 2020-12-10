let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:text = {}
function! doppelganger#text#new(pair_info) abort
  let s:text = extend(s:text, a:pair_info)
  let text_info = deepcopy(s:text)
  return text_info
endfunction

function! s:text.Set() abort dict
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

function! s:text._Set() abort dict
  let self.fillable_width = self._Detect_fillable_width()

  let self.text = ''
  let self.text = self._Join()
  let self.text = self._Truncate_as_fillable_width()
  return self.text
endfunction

function! s:text._Detect_fillable_width() abort dict
  const lnum = self.curr_lnum
  const max_column_width = s:get_config('max_column_width')
  const line = getline(lnum)
  const fillable_width = max_column_width - len(line)

  return fillable_width
endfunction

function! s:text._Join() abort dict
  const prefix = s:get_config('prefix')
  const shim = s:get_config('shim_to_join')

  let contents = self._Read_contents_in_pair()
  let contents = self._Trancate_contents_to_join()

  const text = prefix . join(contents, shim)
  return text
endfunction

function! s:text._Read_contents_in_pair() abort dict
  let self.contents = []

  if self.reverse
    let self.contents = [getline(self.lnum)]
    return self.contents
  endif

  const start = self.lnum
  const end = self.curr_lnum
  let self.contents = getline(start, end)

  return self.contents
endfunction

function! s:text._Trancate_contents_to_join() abort dict
  let contents = self.contents
  let self.contents = map(contents, 'substitute(v:val, ''^\s*\|\s*$'', "", "")')
  return self.contents
endfunction

function! s:text._Truncate_as_corresponding_pattern() abort "{{{2
  const text = self.text
  if !g:doppelganger#text#conceal_corresponding_pattern
    return text
  endif

  try
    " TODO: make it applicable multiple patterns
    let pat_open = get(self, 'reverse', 0) == 1
          \ ? get(self.following, 0)
          \ : get(self.preceding, 0)
  catch
    throw '[Doppelganger] invalid value: '. get(self, 'patterns', '')
  endtry

  " Truncate text at dispensable part:
  " Remove pat_open in head/tail on text.
  "   call s:foo( -> s:foo
  "   function! s:bar(aaa, bbb) -> s:bar(aaa, bbb)
  " Leave pat_open halfway on text.
  "   call s:baz(ccc,ddd) -> call s:baz(ccc,ddd), leave it.
  " The complex pat is especially for nested patterns like
  "   {qux: {
  "     eee : fff,
  "   }}
  " Truncate such texts into `{qux:`, not `qux: {`.
  let pat = pat_open .'\(.*'. pat_open .'\)\@!\S*'
  return substitute(text, pat .'\s*$\|^\s*'. pat, '', 'e')
endfunction

function! s:text._Truncate_as_fillable_width() abort dict
  " TODO: Adapt to unicode
  return self.text[: self.fillable_width]
endfunction

