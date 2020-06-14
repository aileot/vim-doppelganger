" save 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}

let s:get_config = function('doppelganger#util#get_config', ['mapping'])

function! s:set_top() abort
  return max([line('w0'), line('.') - g:doppelganger#ego#max_offset])
endfunction
function! s:set_bot() abort
  return min([line('w$'), line('.') + g:doppelganger#ego#max_offset])
endfunction

nnoremap <silent> <Plug>(doppelganger-update)
      \ :<C-u>call doppelganger#update(<SID>set_top(), <SID>set_bot())<CR>
xnoremap <silent> <Plug>(doppelganger-update)
      \ :<C-u>call doppelganger#update(<SID>set_top(), <SID>set_bot())<CR>

function! doppelganger#mapping#apply() abort
  for char in split(s:get_config('fold_suffixes'), '\zs')
    exe 'silent! nmap <unique> z'. char 'z'. char .'<Plug>(doppelganger-update)'
    exe 'silent! xmap <unique> z'. char 'z'. char .'<Plug>(doppelganger-update)'
  endfor
endfunction

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
