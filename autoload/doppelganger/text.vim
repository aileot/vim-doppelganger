let s:get_config = function('doppelganger#util#get_config', ['text'])

function! doppelganger#text#set(pair_info) abort "{{{2
  let text = s:modify_text(a:pair_info)
  if text ==# '' | return | endif

  let chunks = [[text, a:pair_info.hl_group]]
  let print_lnum = a:pair_info.curr_lnum - 1
  call nvim_buf_set_virtual_text(
        \ 0,
        \ g:__doppelganger_namespace,
        \ print_lnum,
        \ chunks,
        \ {}
        \ )
endfunction

function! s:modify_text(pair_info) abort "{{{2
  let lnum = a:pair_info.lnum
  while lnum > 0
    let text = getline(lnum)
    let text = s:truncate_pat_open(text, a:pair_info)
    let text = substitute(text, '^\s*', '', 'e')
    if text !~# '^\s*$' | break | endif
    let lnum -= 1
  endwhile
  let text = s:get_config('prefix') . text
  return text
endfunction

function! s:truncate_pat_open(text, pair_info) abort "{{{2
  if !g:doppelganger#text#conceal_the_other_end_pattern
    return a:text
  endif

  try
    " TODO: make it applicable multiple patterns
    let pat_open = get(a:pair_info, 'reverse', 0) == 1
          \ ? get(a:pair_info.following, 0)
          \ : get(a:pair_info.preceding, 0)
  catch
    throw '[Doppelganger] invalid value: '. get(a:pair_info, 'patterns', '')
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
  return substitute(a:text, pat .'\s*$\|^\s*'. pat, '', 'e')
endfunction

