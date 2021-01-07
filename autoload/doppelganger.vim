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
  let min_range = get(a:, 1, 0)
  let Haunt = doppelganger#haunt#new(a:upper, a:lower, min_range)
  call Haunt.GetHaunted()
endfunction

function! doppelganger#toggle(upper, lower) abort "{{{1
  if s:is_visible
    call doppelganger#clear()
    return
  endif
  call doppelganger#update(a:upper, a:lower)
  let s:is_visible = 1
endfunction

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
