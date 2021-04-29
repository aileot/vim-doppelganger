" save 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}

let s:candidates = [
      \ 'clear',
      \ 'update',
      \
      \ 'ego',
      \ 'ego/disable',
      \ 'ego/enable',
      \
      \ 'cache/clear',
      \ ]

function! doppelganger#command#complete(A, L, P) abort
  let candidates = deepcopy(s:candidates)

  if doppelganger#ego#is_haunted()
    call filter(candidates, 'v:val !=# "ego/enable"')
  else
    call filter(candidates, 'v:val !=# "ego/disable"')
  endif

  if a:A ==# ''
    return candidates
  endif

  call filter(candidates, 'v:val =~# "^". a:A')

  return candidates
endfunction

function! doppelganger#command#do(line1, line2, ...) abort
  const args = get(a:, 1, '')

  if args =~# '\<cache/clear\>'
    let Cache = doppelganger#cache#new('command')
    call Cache.clear()
  elseif args =~# '\<ego/disable\>'
    call doppelganger#ego#disable()
  elseif args =~# '\<ego/enable\>'
    call doppelganger#ego#enable()
  elseif args =~# '\<ego\>'
    call doppelganger#ego#toggle()
  elseif args =~# '\<update\>'
    call doppelganger#update(a:line1, a:line2)
  elseif args =~# '\<clear\>'
    call doppelganger#clear(a:line1, a:line2)
  else
    call doppelganger#toggle(a:line1, a:line2)
  endif
endfunction

" restore 'cpoptions' {{{1
let &cpo = s:save_cpo
unlet s:save_cpo

" modeline {{{1
" vim:set et sw=2 ts=2 tw=79
