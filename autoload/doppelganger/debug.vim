let g:doppelganger#debug#errormsgs = {}

function! doppelganger#debug#set_errormsg(name, description, value) abort
  let g:doppelganger#debug#errormsgs[a:name] = {
        \ 'description': a:description,
        \ 'value': a:value,
        \ }

  throw 'read `g:doppelganger#debug#errormsgs.'. a:name .'` for detail'
endfunction

