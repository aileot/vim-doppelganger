" ============================================================================
" Repo: kaile256/vim-doppelganger
" File: autoload/doppelganger/ego.vim
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

let s:has_ego = 0

let s:Cache = doppelganger#cache#new('ego')
let s:get_config = function('doppelganger#util#get_config', ['ego'])

function! s:should_disabled() abort "{{{1
  const should_disabled = v:false
        \ || index(g:doppelganger#ego#disable_on_buftypes, &bt) >= 0
        \ || index(g:doppelganger#ego#disable_on_filetypes, &ft) >= 0
  return should_disabled
endfunction

function! doppelganger#ego#update() abort
  const offset = g:doppelganger#ego#max_offset
  const lnum = line('.')

  call s:Cache.Attach(lnum)
  const range = s:Cache.Restore('range')

  if range is# v:null
    const top    = doppelganger#folded#get_apparent_lnum(lnum, - offset)
    const bottom = doppelganger#folded#get_apparent_lnum(lnum,   offset)
    call s:Cache.Update({
          \ 'range': [ top, bottom ],
          \ })
  else
    const [top, bottom] = range
  endif

  call doppelganger#update(top, bottom, g:doppelganger#ego#min_range_of_pairs)
endfunction

function! s:update_window() abort "{{{1
  if s:should_disabled() | return | endif
  call doppelganger#ego#update()
endfunction

function! doppelganger#ego#is_enabled() abort "{{{1
  return s:has_ego
endfunction

function! doppelganger#ego#disable() abort "{{{1
  augroup doppelganger/ego
    au!
  augroup END
  let save_winID = win_getid()
  windo call doppelganger#clear()
  call win_gotoid(save_winID)
  let s:has_ego = 0
endfunction

function! doppelganger#ego#enable() abort "{{{1
  augroup doppelganger/ego
    au!

    au WinLeave * call doppelganger#clear()

    au WinEnter     * call s:update_window()
    au TextChanged  * call s:update_window()
    au TextChangedI * call s:update_window()

    au FileChangedShellPost * call s:update_window()

    if s:get_config('update_on_CursorMoved')
      let s:last_lnum = line('.')
      au CursorMoved * call s:update_for_CursorMoved()
    endif

  augroup END
  let s:has_ego = 1
endfunction

function! doppelganger#ego#toggle() abort "{{{1
  if s:has_ego
    call doppelganger#ego#disable()
    return
  endif
  call doppelganger#ego#enable()
endfunction

function! s:update_for_CursorMoved() abort "{{{2
  if s:should_disabled() | return | endif
  if line('.') == s:last_lnum | return | endif
  call s:update_window()
  let s:last_lnum = line('.')
endfunction

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
