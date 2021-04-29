" save 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}

let s:get_config = function('doppelganger#util#get_config', ['mapping'])

function! s:manual_update() abort
  if !doppelganger#ego#is_haunted() | return | endif
  call doppelganger#ego#update()
endfunction

nnoremap <silent> <Plug>(doppelganger-ego-manual-update) :<C-u>call <SID>manual_update()<CR>
xnoremap <silent> <Plug>(doppelganger-ego-manual-update) :<C-u>call <SID>manual_update()<CR>

function! doppelganger#mapping#apply() abort
  for char in split(s:get_config('fold_suffixes'), '\zs')
    exe 'silent! nmap <unique> z'. char 'z'. char .'<Plug>(doppelganger-ego-manual-update)'
    exe 'silent! xmap <unique> z'. char 'z'. char .'<Plug>(doppelganger-ego-manual-update)'
  endfor
endfunction

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim: et ts=2 sts=2 sw=2 fdm=marker tw=79
