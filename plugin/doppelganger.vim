" ============================================================================
" Repo: kaile256/vim-doppelganger
" File: plugin/doppelganger.vim
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

if !exists('*nvim_buf_set_virtual_text') | finish | endif

if exists('g:loaded_doppelganger') | finish | endif
let g:loaded_doppelganger = 1

" save 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}

function! s:set_default(var, default) abort
  let prefix = matchstr(a:var, '^\w:')
  let suffix = substitute(a:var, prefix, '', '')
  if empty(prefix) || prefix ==# 'l:'
    throw 'l:var is unsupported'
  endif

  let {a:var} = get({prefix}, suffix, a:default)
endfunction

call s:set_default('g:doppelganger#prefix', '◂ ')
call s:set_default('g:doppelganger#pairs', [
      \ ['{', '}'],
      \ ['(', ')'],
      \ ['\[', ']'],
      \ ])
call s:set_default('g:doppelganger#skip_hl_groups', [
      \ 'Comment',
      \ 'String',
      \ ])

call s:set_default('g:doppelganger#ego#max_offset', 3)
call s:set_default('g:doppelganger#ego#update_events', [
      \ 'BufWinEnter',
      \ 'TextChanged',
      \ ])
call s:set_default('g:doppelganger#ego#update_on_CursorMoved', 1)

call s:set_default('g:doppelganger#keymappings', 'oraORA')

command! -bar DoppelgangerClear :call doppelganger#clear()
command! -bar -range=% DoppelgangerUpdate
      \ :call doppelganger#update(<line1>, <line2>)
command! -bar -range=% DoppelgangerToggle
      \ :call doppelganger#toggle(<line1>, <line2>)

command! -bar DoppelgangerEgoDisable :call doppelganger#ego#disable()
command! -bar DoppelgangerEgoEnable  :call doppelganger#ego#enable()
command! -bar DoppelgangerEgoToggle  :call doppelganger#ego#toggle()

call doppelganger#ego#enable()

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
