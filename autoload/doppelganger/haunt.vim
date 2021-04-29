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
  try
    call nvim_buf_set_virtual_text(
          \ 0,
          \ g:__doppelganger_namespace,
          \ a:lnum - 1,
          \ a:chunks,
          \ {}
          \ )
  catch /E5555/
    const description = 'You set chunks in wrong format to nvim_buf_set_virtual_text()'
    call doppelganger#debug#set_errormsg('virtualtext', description, a:chunks)
  endtry
endfunction

function! s:Haunt__is_hl_group_to_skip() abort dict
  const Get_ft_config = function('doppelganger#util#get_config_as_filetype', [''])
  const ignored_groups = Get_ft_config('hl_groups_to_skip')
  const lnum = self.curr_lnum
  const col = len(getline(lnum))
  const group = synIDattr(synID(lnum, col, 0), 'name')
  return group =~? join(ignored_groups, '\|')
endfunction
let s:Haunt.is_hl_group_to_skip = funcref('s:Haunt__is_hl_group_to_skip')

function! s:get_next_unfolded_lnum(lnum, stopline) abort
  const min = line('w0')
  let lnum = a:lnum
  let cnt = a:stopline - a:lnum
  if cnt <= 0
    return -1
  endif

  while cnt && lnum > min
    let foldstart = foldclosed(lnum)
    let lnum = foldstart == -1 ? lnum - 1 : foldstart - 1
    let cnt -= 1
  endwhile

  if foldstart != -1
    return -1
  endif

  return lnum
endfunction

function! s:Haunt__GetHaunted() abort dict
  let save_view = winsaveview()

  const [above, below] = self.range_to_haunt
  const min_range = self.min_range_to_search

  " Search upward from a line under the bottom of window (by an offset).
  let self.curr_lnum = below
  let stop_lnum = s:get_top_lnum(above)
  while self.curr_lnum >= stop_lnum
    if foldclosed(self.curr_lnum) != -1
      let self.curr_lnum = s:get_next_unfolded_lnum(
            \ self.curr_lnum,
            \ stop_lnum,
            \ )
      if self.curr_lnum < 1
        break
      endif
    endif

    call s:Cache.Attach(self.curr_lnum)
    let chunks = s:Cache.Restore('chunks')

    if chunks isnot# v:null
      call s:set_virtualtext(self.curr_lnum, chunks)
      let self.curr_lnum -= 1
      continue
    endif

    let chunks = []

    if self.is_hl_group_to_skip()
      " Note: It's too slow without this guard up to hl_group though this check
      " is too rough for a line which contains both codes and the hl_group.
      call s:Cache.Update({
            \ 'chunks': chunks,
            \ })
      let self.curr_lnum -= 1
      continue
    endif

    let Search = doppelganger#search#new(self.curr_lnum)
    call Search.SetIgnoredRange(min_range)
    call Search.SearchPair()
    let [curr_lnum, corr_lnum] = Search.GetPairLnums()

    if corr_lnum < 1
      let self.curr_lnum -= 1
      continue
    endif

    let info = Search " TODO: Without this copying, ...#format#new() should just get corr_lnum
    let Text = doppelganger#format#new(info)
    let chunks = Text.ComposeChunks()

    call s:set_virtualtext(self.curr_lnum, chunks)
    call s:Cache.Update({
          \ 'chunks': chunks,
          \ })
    let self.curr_lnum -= 1
  endwhile
  call winrestview(save_view)
endfunction
let s:Haunt.GetHaunted = funcref('s:Haunt__GetHaunted')

function! s:get_top_lnum(lnum) abort "{{{2
  const foldstart = foldclosed(a:lnum)
  return foldstart == -1 ? a:lnum : foldstart
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
        \   'lnum': line('.'),
        \   },
        \ ])
  au FileChangedShellPost * call s:Cache.DropOutdated([
        \   {
        \   'region': 'Haunt',
        \   'name':   'chunks',
        \   },
        \ ])
augroup END
