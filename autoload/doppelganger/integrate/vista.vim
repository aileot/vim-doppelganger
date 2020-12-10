" TODO:
" Parse /home/kaile256/.ghq/github.com/karlhadwen/todoist/src/hooks/vista_sample.js
function! doppelganger#integrate#vista#set_text() abort
  let text = getline(a:lnum_open)
  if text ==# '' | return | endif
  let text = s:modify_text(text, a:lnum_open)
  let chunks = [[text, a:hl_group]]
  let print_lnum = s:cur_lnum - 1
  call nvim_buf_set_virtual_text(
        \ 0,
        \ s:namespace,
        \ print_lnum,
        \ chunks,
        \ {},
        \ )
endfunction
