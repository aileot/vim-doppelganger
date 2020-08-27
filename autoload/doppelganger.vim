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
let s:hl_group = 'DoppelgangerVirtualText'
let s:hl_group_pair = s:hl_group .'Pair'
let s:hl_group_pair_reverse = s:hl_group .'PairReverse'
exe 'hi def link' s:hl_group 'NonText'
exe 'hi def link' s:hl_group_pair s:hl_group
exe 'hi def link' s:hl_group_pair_reverse s:hl_group

let s:is_visible = 0

" Helper Functions {{{1
let s:get_config = function('doppelganger#util#get_config', [''])
let s:get_config_as_filetype =
      \ function('doppelganger#util#get_config_as_filetype', [''])

function! s:last_item(arr) abort
  return a:arr[len(a:arr) - 1]
endfunction

function! s:is_hl_group_to_skip() abort "{{{1
  let hl_groups = get(b:, 'doppelganger_hl_groups_to_skip')
  if !hl_groups
    if has_key(g:doppelganger#hl_groups_to_skip, &ft)
      let hl_groups = g:doppelganger#hl_groups_to_skip[&ft]
    else
      let hl_groups = g:doppelganger#hl_groups_to_skip['_']
    endif
  endif
  return synIDattr(synID(line('.'), col('.'), 0), 'name')
        \ =~? join(hl_groups, '\|')
endfunction

function! doppelganger#clear() abort "{{{1
  call nvim_buf_clear_namespace(0, s:namespace, 1, -1)
  let s:is_visible = 0
endfunction

function! doppelganger#update(upper, lower, ...) abort "{{{1
  " Guards {{{
  " Guard if virtualtext is unavailable.
  if !exists('*nvim_buf_set_virtual_text')
    echoerr 'DoppelGanger requires nvim_buf_set_virtual_text() available;'
    echoerr 'you have to use Neovim 0.3.2+.'
    return
  endif

  " Guard for compatibility with snippets.
  if mode() ==? 's' | return | endif
  "}}}

  call doppelganger#clear()
  let min_range = a:0 > 0 ? a:1 : g:doppelganger#min_range_of_pairs
  call s:deploy_doppelgangers(a:upper, a:lower, min_range)
endfunction

function! doppelganger#toggle(upper, lower) abort "{{{1
  if s:is_visible
    call doppelganger#clear()
    return
  endif
  call doppelganger#update(a:upper, a:lower)
  let s:is_visible = 1
endfunction

function! s:deploy_doppelgangers(upper, lower, min_range) abort "{{{1
  let save_view = winsaveview()

  " Search upward from a line under the bottom of window (by an offset).
  let s:cur_lnum = s:get_bottom_lnum(a:lower)
  let stop_lnum = s:get_top_lnum(a:upper)
  while s:cur_lnum >= stop_lnum
    let s:cur_lnum = s:update_curpos(stop_lnum)
    if s:is_hl_group_to_skip()
      " Note: It's too slow without this guard up to hl_group though this check
      " is too rough for a line which contains both codes and the hl_group.
      let s:cur_lnum -= 1
      continue
    endif

    let leader_lnum = s:get_leader_lnum()
    if leader_lnum > 0
      call s:set_text_on_lnum(leader_lnum, s:hl_group_pair_reverse)
      let s:pat_the_other = leader_lnum
    else
      let the_pair = s:specify_the_outermost_pair_in_the_line(s:cur_lnum)
      if the_pair != []
        let s:pat_the_other = the_pair[0]
        let lnum_open = s:get_lnum_open(the_pair, a:min_range)
        call s:set_text_on_lnum(lnum_open, s:hl_group_pair)
      endif
    endif

    let s:cur_lnum -= 1
  endwhile
  call winrestview(save_view)
endfunction

function! s:get_bottom_lnum(lnum) abort "{{{2
  " close side like '}'
  let lnum = a:lnum < 0 ? 1 : a:lnum
  if !s:is_folded(lnum)
    return lnum
  endif

  let diff = lnum - foldclosed(lnum)
  while diff > 0
    " FIXME: Consider range over mixed lines folded and raw.
    let ret = lnum + diff
    if !s:is_folded(ret)
      return ret
    endif
    let diff = ret - foldclosed(ret)
  endwhile
endfunction

function! s:get_top_lnum(lnum) abort "{{{2
  " open side like '{'
  let lnum = a:lnum > line('$') ? line('$') : a:lnum
  let foldstart = foldclosed(lnum)
  let ret = foldstart == -1 ? lnum : foldstart
  return ret
endfunction

function! s:get_leader_lnum() abort "{{{2
  " Return Number. If return 0, it behaves as failure.
  " Search followers forwards.

  let pairs = s:set_pairs_reverse()
  let line = getline('.')
  for p in pairs
    let leader = p[0]
    if line =~# leader
      let followers = p[1:]
      for f in followers
        let lnum = s:_search_leader_lnum(leader, f)
        return lnum
      endfor
    endif
  endfor

  return 0
endfunction

function! s:set_pairs_reverse() abort "{{{2
  if exists('b:doppelganger_pairs_reverse')
    return b:doppelganger_pairs_reverse
  endif

  let groups = has_key(g:doppelganger#pairs_reverse, &ft)
        \ ? deepcopy(g:doppelganger#pairs_reverse[&ft])
        \ : deepcopy(g:doppelganger#pairs_reverse['_'])

  return groups
endfunction

function! s:_search_leader_lnum(pat_leader, pat_follower) abort
  let flags_unmove_downward_exc = 'nWz'
  let Skip_comments = 's:is_hl_group_to_skip()'
  let lnum_leader = searchpair(a:pat_leader, '', a:pat_follower,
        \ flags_unmove_downward_exc, Skip_comments)
  return lnum_leader
endfunction

function! s:specify_the_outermost_pair_in_the_line(lnum) abort "{{{2
  let line = getline(a:lnum)
  let pairs = s:set_pairs()

  for p in pairs
    let pat_close = s:last_item(p)
    let pat_close_at_endOfLine = s:append_endOfLine_pattern(pat_close)
    let match = matchstr(line, pat_close_at_endOfLine)
    if len(match)
      return p
    endif
  endfor

  return []
endfunction

function! s:set_pairs() abort "{{{2
  if exists('b:_doppelganger_pairs')
    return get(b:, 'doppelganger_pairs', []) + b:_doppelganger_pairs
  endif

  let pairs = has_key(g:doppelganger#pairs, &ft)
        \ ? deepcopy(g:doppelganger#pairs[&ft])
        \ : deepcopy(g:doppelganger#pairs['_'])
  if exists('b:match_words')
    let pairs += s:parse_matchwords()
    let pairs = sort(pairs, 's:sort_by_length_desc')
    let b:_doppelganger_pairs = pairs
  endif

  return pairs
endfunction

function! s:parse_matchwords() abort "{{{2
  let pairs = split(b:match_words, ',')
  call filter(pairs, '!empty(v:val)')
  call map(pairs, 'split(v:val, ":")')
  call map(pairs, function('s:swap_atoms'))
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

function! s:sort_by_length_desc(pair1, pair2) abort "{{{2
  return len(a:pair2[0]) - len(a:pair1[0])
endfunction

function! s:append_endOfLine_pattern(pat) abort
  let separators_at_end = ',;'

  " Sample: to get correct pattern
  " $
  " \$
  let pat_at_end = ''
  if a:pat =~# '\\v'
    let pat_at_end = a:pat =~# '\\\@<!$$'
          \ ? ''
          \ : '['. separators_at_end .']?$'
  elseif a:pat =~# '\\V'
    let pat_at_end = a:pat =~# '\\$$'
          \ ? ''
          \ : '\['. separators_at_end .']\?\$'
  elseif a:pat =~# '\\M'
    let pat_at_end = a:pat =~# '\\\@<!$$'
          \ ? ''
          \ : '\['. separators_at_end .']\?$'
  elseif a:pat !~# '\\\@<!$$'
    let pat_at_end = '['. separators_at_end .']\?$'
  endif

  return a:pat . pat_at_end
endfunction

function! s:get_lnum_open(pair_dict, min_range) abort "{{{2
  let pat_open = a:pair_dict[0]
  let pat_close = s:last_item(a:pair_dict)
  let flags_mobile_upward_inc = 'cbW'
  let flags_unmove_upward_exc = 'nbWz'
  let Skip_comments = 's:is_hl_group_to_skip()'

  norm! $
  let lnum_close = search(pat_close, flags_mobile_upward_inc)
  " searchpair() fails to parse line-continuation with 'c'-flag
  let lnum_open = searchpair(pat_open, '', pat_close,
        \ flags_unmove_upward_exc, Skip_comments)

  if lnum_open > lnum_close - a:min_range
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

function! s:set_text_on_lnum(lnum_open, hl_group) abort "{{{2
  let text = getline(a:lnum_open)
  if text ==# '' | return | endif
  let text = s:modify_text(text, a:lnum_open)
  let chunks = [[text, a:hl_group]]
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
  if !g:doppelganger#conceal_the_other_end_pattern
    return a:text
  endif

  let pat_open = s:pat_the_other
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
