let s:Cache = doppelganger#cache#new('Haunt')
let s:Haunt = {}

function! doppelganger#haunt#new(above, below) abort "{{{1
  let Haunt = deepcopy(s:Haunt)
  let Haunt.range_to_haunt = [a:above, a:below]
  return Haunt
endfunction

function! s:Haunt__SetMinRange(num) abort dict
  let self.min_range_to_search = a:num
endfunction
let s:Haunt.SetMinRange = funcref('s:Haunt__SetMinRange')


function! s:Haunt__GetHaunted() abort dict
  let save_view = winsaveview()

  const [above, below] = self.range_to_haunt
  const min_range = self.min_range_to_search

  " Search upward from a line under the bottom of window (by an offset).
  let s:curr_lnum = s:get_bottom_lnum(below)
  let stop_lnum = s:get_top_lnum(above)
  while s:curr_lnum >= stop_lnum
    let s:curr_lnum = s:update_curpos(stop_lnum)
    if doppelganger#highlight#_is_hl_group_to_skip()
      " Note: It's too slow without this guard up to hl_group though this check
      " is too rough for a line which contains both codes and the hl_group.
      let s:curr_lnum -= 1
      continue
    endif

    let follower_info = doppelganger#search#get_pair_info(s:curr_lnum, 'b', min_range)
    if get(follower_info, 'corr_lnum') > 0
      let follower_info.curr_lnum = s:curr_lnum
      let follower_info.hl_group = g:doppelganger#highlight#_pair_reverse
      let Text = doppelganger#text#new(follower_info)
      call Text.SetVirtualtext()
    else
      let open_info = doppelganger#search#get_pair_info(s:curr_lnum, '', min_range)
      let open_info.curr_lnum = s:curr_lnum
      let open_info.hl_group = g:doppelganger#highlight#_pair
      if get(open_info, 'corr_lnum') > 0
        let Text = doppelganger#text#new(open_info)
        call Text.SetVirtualtext()
      endif
    endif

    let s:curr_lnum -= 1
  endwhile
  call winrestview(save_view)
endfunction
let s:Haunt.GetHaunted = funcref('s:Haunt__GetHaunted')

function! s:get_bottom_lnum(lnum) abort "{{{2
  " close side like '}'
  let lnum = a:lnum < 0 ? 1 : a:lnum
  if !s:is_folded(lnum)
    return lnum
  endif

  let diff = lnum - foldclosed(lnum)
  while diff > 0
    " FIXME: Consider range over mixed lines folded and raw.
    let ret = lnum + diff
    if !s:is_folded(ret)
      return ret
    endif
    let diff = ret - foldclosed(ret)
  endwhile
endfunction

function! s:get_top_lnum(lnum) abort "{{{2
  " open side like '{'
  let lnum = a:lnum > line('$') ? line('$') : a:lnum
  let foldstart = foldclosed(lnum)
  let ret = foldstart == -1 ? lnum : foldstart
  return ret
endfunction

function! s:update_curpos(stop_lnum) abort "{{{2
  let lnum = s:curr_lnum
  if !s:is_folded(lnum)
    exe lnum
    return lnum
  endif

  let save_next = lnum
  while s:is_folded(lnum) || lnum > a:stop_lnum
    if lnum > 0
      let save_next = lnum
      let lnum -= 1
    endif
    let lnum = foldclosed(lnum)
  endwhile

  exe save_next
  return save_next
endfunction

function! s:is_folded(lnum) abort "{{{2
  return foldclosed(a:lnum) != -1
endfunction


