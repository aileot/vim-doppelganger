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

let s:get_config = function('doppelganger#util#get_config', ['ego'])
let s:top = {-> max([line('w0'), line('.') - g:doppelganger#ego#max_offset])}
let s:bot = {-> min([line('w$'), line('.') + g:doppelganger#ego#max_offset])}

function! doppelganger#ego#disable() abort "{{{1
  augroup doppelganger
    au!
  augroup END
  windo call doppelganger#clear()
  let s:has_ego = 0
endfunction

function! doppelganger#ego#enable() abort "{{{1
  windo call doppelganger#update(s:top(), s:bot())
  let events = join(s:get_config('update_events'), ',')
  augroup doppelganger
    " TODO: Update text on fold open, or map to `zo`, `zr` and so on?
    au!
    exe 'au' events
          \ '* call doppelganger#update(s:top(), s:bot())'
  augroup END

  if s:get_config('update_on_CursorMoved')
    call s:update_on_CursorMoved()
  endif
  let s:has_ego = 1
endfunction

function! doppelganger#ego#toggle() abort "{{{1
  if s:has_ego
    call doppelganger#ego#disable()
    return
  endif
  call doppelganger#ego#enable()
endfunction

function! s:update_on_CursorMoved() abort "{{{1
  let s:last_lnum = line('.')
  augroup doppelganger
    au CursorMoved * call s:update_for_CursorMoved()
  augroup END
endfunction

function! s:update_for_CursorMoved() abort "{{{2
  if line('.') == s:last_lnum | return | endif
  call doppelganger#update(s:top(), s:bot())
  let s:last_lnum = line('.')
endfunction

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
