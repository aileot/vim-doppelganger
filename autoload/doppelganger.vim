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

let g:__doppelganger_namespace = nvim_create_namespace('doppelganger')
let s:is_visible = 0

" Helper Functions {{{1
let s:get_config = function('doppelganger#util#get_config', [''])
let s:get_config_as_filetype =
      \ function('doppelganger#util#get_config_as_filetype', [''])

function! doppelganger#clear() abort "{{{1
  call nvim_buf_clear_namespace(0, g:__doppelganger_namespace, 1, -1)
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
    if doppelganger#highlight#_is_hl_group_to_skip()
      " Note: It's too slow without this guard up to hl_group though this check
      " is too rough for a line which contains both codes and the hl_group.
      let s:cur_lnum -= 1
      continue
    endif

    let follower_info = doppelganger#search#get_pair_info(s:cur_lnum, 'b', a:min_range)
    if get(follower_info, 'lnum') > 0
      let follower_info.curr_lnum = s:cur_lnum
      let follower_info.hl_group = g:doppelganger#highlight#_pair_reverse
      let Text = doppelganger#text#new(follower_info)
      call Text.Set()
    else
      let open_info = doppelganger#search#get_pair_info(s:cur_lnum, '', a:min_range)
      let open_info.curr_lnum = s:cur_lnum
      let open_info.hl_group = g:doppelganger#highlight#_pair
      if get(open_info, 'lnum') > 0
        let Text = doppelganger#text#new(open_info)
        call Text.Set()
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

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
