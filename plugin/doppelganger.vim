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

hi def      DoppelgangerVirtualtextPrefix   ctermfg=243 guifg=#767676
hi def      DoppelgangerVirtualtextContents ctermfg=64 guifg=#5f8700
hi def link DoppelgangerVirtualtextShim     DoppelgangerVirtualtextPrefix
hi def link DoppelgangerVirtualtextEllipsis DoppelgangerVirtualtextContents
hi def link DoppelgangerVirtualtextSuffix   DoppelgangerVirtualtextPrefix

hi def link DoppelgangerVirtualtextReversePrefix   DoppelgangerVirtualtextPrefix
hi def      DoppelgangerVirtualtextReverseContents ctermfg=130 guifg=#df5f29
hi def link DoppelgangerVirtualtextReverseShim     DoppelgangerVirtualtextShim
hi def link DoppelgangerVirtualtextReverseEllipsis DoppelgangerVirtualtextEllipsis
hi def link DoppelgangerVirtualtextReverseSuffix   DoppelgangerVirtualtextReversePrefix

function! s:set_default(var, default) abort
  let prefix = matchstr(a:var, '^\w:')
  let suffix = substitute(a:var, prefix, '', '')
  if empty(prefix) || prefix ==# 'l:'
    throw 'l:var is unsupported'
  endif

  let {a:var} = get({prefix}, suffix, a:default)
endfunction

call s:set_default('g:doppelganger#format#prefix',       [
      \ [['◂ {absolute}: ', 'DoppelgangerVirtualtextPrefix']],
      \ [['◂ {absolute}: ', 'DoppelgangerVirtualtextReversePrefix']],
      \ ])
call s:set_default('g:doppelganger#format#suffix',       [
      \ [[' [{relative}]', 'DoppelgangerVirtualtextSuffix']],
      \ [[' [{relative}]', 'DoppelgangerVirtualtextReverseSuffix']],
      \ ])
call s:set_default('g:doppelganger#format#shim', [
      \ [[' ﲖ ', 'DoppelgangerVirtualtextShim']],
      \ [[' ﲖ ', 'DoppelgangerVirtualtextReverseShim']],
      \ ])
call s:set_default('g:doppelganger#format#ellipsis',     [
      \ [[' …', 'DoppelgangerVirtualtextEllipsis']],
      \ [[' …', 'DoppelgangerVirtualtextReverseEllipsis']],
      \ ])
call s:set_default('g:doppelganger#format#hl_contents',  [
      \ ['DoppelgangerVirtualtextContents'],
      \ ['DoppelgangerVirtualtextReverseContents'],
      \ ])

call s:set_default('g:doppelganger#format#contents_depth', 10)
call s:set_default('g:doppelganger#format#compress_whitespaces', 1)
call s:set_default('g:doppelganger#format#ignore_blanklines', 1)

call s:set_default('g:doppelganger#format#max_column_width',
      \ 'max([&cc - 1, &tw, 79])')

call s:set_default('g:doppelganger#search#pairs', {
      \ '_': [
      \   ['{', '}[,;]\?'],
      \   ['(', ')[,;]\?'],
      \   ['\[', '\][,;]\?'],
      \   ],
      \ })
call s:set_default('g:doppelganger#search#pairs_reverse', {
      \ '_': [
      \   ['\s*do {.*', '\s*}\s*while (.*).*'],
      \ ],
      \ })
call s:set_default('g:doppelganger#hl_groups_to_skip', {
      \ '_': [
      \   'Comment',
      \   'String',
      \ ],
      \ 'json': [
      \   'jsonKeyword',
      \ ]})

call s:set_default('g:doppelganger#ego#disable_autostart', 0)
call s:set_default('g:doppelganger#ego#disable_on_buftypes', [
      \ 'help',
      \ 'prompt',
      \ 'quickfix',
      \ 'terminal',
      \ ])
call s:set_default('g:doppelganger#ego#disable_on_filetypes', [
      \ 'agit',
      \ 'defx',
      \ 'fugitive',
      \ 'git',
      \ 'gitcommit',
      \ 'gitrebase',
      \ 'help',
      \ 'man',
      \ 'markdown',
      \ 'netrw',
      \ 'pullrequest',
      \ 'tagbar',
      \ 'text',
      \ 'vista',
      \ ])

call s:set_default('g:doppelganger#ego#min_range_of_pairs', 4)
call s:set_default('g:doppelganger#ego#max_offset', 3)
call s:set_default('g:doppelganger#ego#update_on_CursorMoved', 1)

call s:set_default('g:doppelganger#mapping#fold_suffixes', 'voraxcmORAXCM')

call s:set_default('g:doppelganger#cache#disable', v:false)

call s:set_default('g:doppelganger#debug', v:false)

command! -bar -range=% -nargs=? -complete=customlist,doppelganger#command#complete
      \ Doppelganger
      \ :call doppelganger#command#do(<line1>, <line2>, <f-args>)

if !g:doppelganger#ego#disable_autostart
  call doppelganger#ego#enable()
endif

if g:doppelganger#mapping#fold_suffixes !=# ''
  call doppelganger#mapping#apply()
endif

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
