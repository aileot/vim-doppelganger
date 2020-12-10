let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:text = {}
function! doppelganger#text#new(pair_info) abort
  let s:text = extend(s:text, a:pair_info)
  let text_info = deepcopy(s:text)
  return text_info
endfunction

function! s:text.Set() abort dict "{{{2
  let text = self._Modify()
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

function! s:text._Modify() abort dict "{{{2
  let self.fillable_width = self._Detect_fillable_width()

  let lnum = self.lnum
  while lnum > 0
    let self.text = getline(lnum)
    let self.text = self._Truncate_as_corresponding_pattern()
    let self.text = substitute(self.text, '^\s*', '', 'e')
    if self.text !~# '^\s*$' | break | endif
    let lnum -= 1
  endwhile
  let self.text = s:get_config('prefix') . self.text
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

function! s:text._Truncate_as_corresponding_pattern() abort dict "{{{2
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

