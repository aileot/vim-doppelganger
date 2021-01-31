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

function! s:set_virtualtext(lnum, chunks) abort
  call nvim_buf_set_virtual_text(
        \ 0,
        \ g:__doppelganger_namespace,
        \ a:lnum - 1,
        \ a:chunks,
        \ {}
        \ )
endfunction

function! s:Haunt__GetHaunted() abort dict
  let save_view = winsaveview()

  const [above, below] = self.range_to_haunt
  const min_range = self.min_range_to_search

  " Search upward from a line under the bottom of window (by an offset).
  let s:curr_lnum = s:get_bottom_lnum(below)
  let stop_lnum = s:get_top_lnum(above)
  while s:curr_lnum >= stop_lnum
    let s:curr_lnum = s:update_curpos(stop_lnum)

    call s:Cache.Attach(s:curr_lnum)
    let chunks = s:Cache.Restore('chunks')

    if chunks isnot# v:null
      call s:set_virtualtext(s:curr_lnum, chunks)
      let s:curr_lnum -= 1
      continue
    endif

    let chunks = []

    if doppelganger#highlight#_is_hl_group_to_skip()
      " Note: It's too slow without this guard up to hl_group though this check
      " is too rough for a line which contains both codes and the hl_group.
      call s:Cache.Update({
            \ 'chunks': chunks,
            \ })
      let s:curr_lnum -= 1
      continue
    endif

    let Search = doppelganger#search#new(s:curr_lnum)
    call Search.SetIgnoredRange(min_range)
    call Search.SearchPair()
    let [curr_lnum, corr_lnum] = Search.GetPairLnums()

    if corr_lnum < 1
      let s:curr_lnum -= 1
      continue
    endif

    let hl_group = Search.IsReverse()
          \ ? g:doppelganger#highlight#_pair_reverse
          \ : g:doppelganger#highlight#_pair

    let info = Search " TODO: Without this copying, ...#text#new() should just get corr_lnum
    let Text = doppelganger#text#new(info)
    call Text.SetHlGroup(hl_group)
    let chunks = Text.ComposeChunks()

    call s:set_virtualtext(s:curr_lnum, chunks)
    call s:Cache.Update({
          \ 'chunks': chunks,
          \ })
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


augroup doppelganger/haunt
  au!
  au BufWinLeave * call s:Cache.DropOutdated([
        \   {
        \   'region': 'Haunt',
        \   'name':   'chunks',
        \   },
        \ ])
  au TextChanged * call s:Cache.DropOutdated([
        \   {
        \   'region': 'Haunt',
        \   'name':   'chunks',
        \   },
        \ ])
  au TextChangedI * call s:Cache.DropOutdated([
        \   {
        \   'region': 'Haunt',
        \   'name':   'chunks',
        \   },
        \ ])
augroup END
