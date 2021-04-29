function! s:apparent_top(lnum, offset) abort
  const min = line('w0')
  let lnum = a:lnum
  let cnt = a:offset

  while cnt && lnum > min
    let foldstart = foldclosed(lnum)
    let lnum = foldstart == -1 ? lnum - 1 : foldstart - 1
    let cnt -= 1
  endwhile

  return lnum
endfunction

function! s:apparent_bottom(lnum, offset) abort
  const max = line('w$')
  let lnum = a:lnum
  let cnt = a:offset

  while cnt && lnum < max
    let foldend = foldclosedend(lnum)
    let lnum = foldend == -1 ? lnum + 1 : foldend + 1
    let cnt -= 1
  endwhile

  let foldstart = foldclosed(lnum)
  return foldstart == -1 ? lnum : foldstart
endfunction

function! doppelganger#folded#get_apparent_lnum(lnum, offset) abort
  const lnum = a:offset < 0
        \ ? s:apparent_top(a:lnum,  - a:offset)
        \ : s:apparent_bottom(a:lnum, a:offset)
  return lnum
endfunction

