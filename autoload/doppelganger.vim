" ============================================================================
" Repo: kaile256/vim-doppelganger
" File: autoload/doppelganger.vim
" Author: kaile256
" License: MIT license {{{
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
" ============================================================================

" save 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}

let s:namespace = nvim_create_namespace('doppelganger')
let s:hl_group = 'Doppelganger'
exe 'hi def link' s:hl_group 'NonText'

let s:is_visible = 0

" Helper Functions {{{1
let s:get_config = function('doppelganger#util#get_config', [''])

function! s:last_item(arr) abort
  return a:arr[len(a:arr) - 1]
endfunction

function! s:is_skip_hl_group() abort "{{{1
  let hl_groups = get(b:, 'doppelganger_skip_hl_groups')
  if !hl_groups
    if has_key(g:doppelganger#skip_hl_groups, &ft)
      let hl_groups = g:doppelganger#skip_hl_groups[&ft]
    else
      let hl_groups = g:doppelganger#skip_hl_groups['_']
    endif
  endif
  return synIDattr(synID(line('.'), col('.'), 0), 'name')
        \ =~? join(hl_groups, '\|')
endfunction

function! doppelganger#clear() abort "{{{1
  call nvim_buf_clear_namespace(0, s:namespace, 1, -1)
  let s:is_visible = 0
endfunction

function! doppelganger#update(upper, lower) abort "{{{1
  call doppelganger#clear()
  call doppelganger#fill(a:upper, a:lower)
endfunction

function! doppelganger#toggle(upper, lower) abort "{{{1
  if s:is_visible
    call doppelganger#clear()
    return
  endif
  call doppelganger#update(a:upper, a:lower)
  let s:is_visible = 1
endfunction

function! doppelganger#fill(upper, lower) abort "{{{1
  " Guards {{{
  " Guard if virtualtext is unavailable.
  if !exists('*nvim_buf_set_virtual_text')
    echoerr 'DoppelGanger requires nvim_buf_set_virtual_text() available;'
    echoerr 'you have to use Neovim 0.3.2+.'
    return
  endif

  " Guard for compatibility with snippets.
  if mode() ==? 's' | return | endi
  "}}}

  let save_view = winsaveview()

  " Search upward from a line under the bottom of window (by an offset).
  let s:cur_lnum = s:get_bottom_lnum(a:lower)
  let stop_lnum = s:get_top_lnum(a:upper)
  while s:cur_lnum >= stop_lnum
    let s:cur_lnum = s:update_curpos(stop_lnum)
    if s:is_skip_hl_group()
      " Note: It's too slow without this guard up to hl_group though this check
      " is too rough for a line which contains both codes and the hl_group.
      let s:cur_lnum -= 1
      continue
    endif
    let the_pair = s:specify_the_outermost_pair_in_the_line(s:cur_lnum)
    if the_pair != []
      let lnum_open = s:get_lnum_open(the_pair)
      call s:set_text_on_lnum(lnum_open)
    endif
    let s:cur_lnum -= 1
  endwhile
  call winrestview(save_view)
endfunction

function! s:get_bottom_lnum(lnum) abort "{{{2
  " close side like '}'
  let lnum = a:lnum < 0 ? 1 : a:lnum
  let foldend = foldclosedend(lnum)
  let ret = foldend == -1 ? lnum : foldend + a:lnum - foldclosed(a:lnum)
  return ret
endfunction

function! s:get_top_lnum(lnum) abort "{{{2
  " open side like '{'
  let lnum = a:lnum > line('$') ? line('$') : a:lnum
  let foldstart = foldclosed(lnum)
  let ret = foldstart == -1 ? lnum : foldstart
  return ret
endfunction

function! s:specify_the_outermost_pair_in_the_line(lnum) abort "{{{2
  let line = getline(a:lnum)
  " matchend() never returns 0.
  let biggest_match_col = 0
  let the_pair = []
  silent! unlet s:the_pair
  let pairs = s:set_pairs()

  for p in pairs
    let match_col = 0
    while match_col != -1
      let match_col = matchend(line, s:last_item(p), match_col)
      if match_col > biggest_match_col
        let biggest_match_col = match_col
        let the_pair = p
      endif
    endwhile
  endfor

  let s:the_pair = the_pair
  return the_pair
endfunction

function! s:set_pairs() abort "{{{2
  if exists('b:doppelganger_pairs')
    return b:doppelganger_pairs
  elseif exists('b:match_words')
    let b:doppelganger_pairs = s:parse_matchwords() + g:doppelganger#pairs
  endif

  return g:doppelganger#pairs
endfunction

function! s:parse_matchwords() abort "{{{2
  let pairs = split(b:match_words, ',')
  call map(pairs, 'split(v:val, ":")')
  call map(pairs, function("s:swap_atoms"))
  return pairs
endfunction

function! s:swap_atoms(_, pat) abort "{{{2
  if s:last_item(a:pat) !~# '\\\d'
    return a:pat
  endif

  let pat = a:pat
  let cnt = 0
  let pat_to_save = '\\(.\{-}\\)'
  while s:last_item(pat) =~# '\\\d'
    " Sample from vim-closetag:
    " ['<\@<=\([^/][^ \t>]*\)\%(>\|$\|[ \t][^>]*\%(>\|$\)\)', '<\@<=/\1>']
    let cnt += 1
    let pat_atom = '\\'. cnt
    let save_match = matchstr(pat[0], pat_to_save)
    let pat[0] = substitute(pat[0], pat_to_save, pat_atom, 'e')
    let pat[len(pat) - 1] = substitute(s:last_item(pat), pat_atom, save_match, 'e')
  endwhile
  return pat
endfunction

function! s:get_lnum_open(pair_dict) abort "{{{2
  let pat_open = a:pair_dict[0]
  let pat_close = s:last_item(a:pair_dict)
  let flags_mobile_upward_inc = 'cbW'
  let flags_unmove_upward_exc = 'nbWz'
  let Skip_comments = 's:is_skip_hl_group()'

  norm! $
  let lnum_close = search(pat_close, flags_mobile_upward_inc)
  " searchpair() fails to parse line-continuation with 'c'-flag
  let lnum_open = searchpair(pat_open, '', pat_close,
        \ flags_unmove_upward_exc, Skip_comments)

  if lnum_open == lnum_close
    " Continue the while loop anyway.
    return 0
  endif

  return lnum_open
endfunction

function! s:update_curpos(stop_lnum) abort "{{{2
  let lnum = s:cur_lnum
  if !s:is_folded(lnum)
    exe lnum
    return lnum
  endif

  let save_next = lnum
  while s:is_folded(lnum) || lnum > a:stop_lnum
    if lnum > 0
      let save_next = lnum
      let lnum -= 1
    endif
    let lnum = foldclosed(lnum)
  endwhile

  exe save_next
  return save_next
endfunction

function! s:is_folded(lnum) abort "{{{2
  return foldclosed(a:lnum) != -1
endfunction

function! s:set_text_on_lnum(lnum_open) abort "{{{2
  let text = getline(a:lnum_open)
  if text ==# '' | return | endif
  let text = s:modify_text(text, a:lnum_open)
  let chunks = [[text, s:hl_group]]
  let print_lnum = s:cur_lnum - 1
  call nvim_buf_set_virtual_text(
        \ 0,
        \ s:namespace,
        \ print_lnum,
        \ chunks,
        \ {}
        \ )
endfunction

function! s:modify_text(text, lnum) abort "{{{2
  let lnum = a:lnum
  let text = a:text
  while lnum > 0
    let text = getline(lnum)
    let text = s:truncate_pat_open(text)
    let text = substitute(text, '^\s*', '', 'e')
    if text !~# '^\s*$' | break | endif
    let lnum -= 1
  endwhile
  let text = s:get_config('prefix') . text
  return text
endfunction

function! s:truncate_pat_open(text) abort "{{{2
  let pat_open = s:the_pair[0]
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

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
