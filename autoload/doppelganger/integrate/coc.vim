function! RunAsync() abort
  call s:Dispatch('s:RunAsync')
  let g:data = s:data
endfunction

function! s:Dispatch(F, ...) abort
  if !exists('*CocActionAsync')
    echohl ErrorMsg
    echo "coc.nvim isn't loaded!"
    echohl Normal
    return
  endif

  return call(function(a:F), a:000)
endfunction

function! s:Execute(bang, should_display) abort
  let s:fpath = expand('%:p')

  if a:bang
    call s:Extract(CocAction('documentSymbols'))
    if a:should_display
      call vista#renderer#RenderAndDisplay(s:data)
    endif
  else
    let s:should_display = a:should_display
    call s:RunAsync()
  endif
endfunction

function! s:RunAsync() abort
  call CocActionAsync('documentSymbols', function('s:HandleLSPResponseInSilence'))
endfunction

function! s:HandleLSPResponseInSilence(error, response) abort
  if empty(a:error) && a:response isnot v:null
    call s:Extract(a:response)
  endif
endfunction

function! s:Extract(symbols) abort
  let s:data = []

  if empty(a:symbols)
    return
  endif

  let g:vista.functions = []
  let g:vista.raw = []
  call map(a:symbols, 's:parse_coc_symbols(v:val, s:data)')

  return s:data
endfunction

function! s:parse_coc_symbols(symbol, container) abort
  let raw = { 'line': a:symbol.lnum, 'kind': a:symbol.kind, 'name': a:symbol.text }
  call add(g:vista.raw, raw)

  if a:symbol.kind ==? 'Method' || a:symbol.kind ==? 'Function'
    call add(g:vista.functions, a:symbol)
  endif

  call add(a:container, {
        \ 'lnum': a:symbol.lnum,
        \ 'col': a:symbol.col,
        \ 'text': a:symbol.text,
        \ 'kind': a:symbol.kind,
        \ 'level': a:symbol.level
        \ })
endfunction

