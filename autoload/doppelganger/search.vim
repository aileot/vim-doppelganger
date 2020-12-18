let s:get_config_as_filetype =
      \ function('doppelganger#util#get_config_as_filetype', ['search'])

let s:Search = {}
function! doppelganger#search#new(arg) abort
  if type(a:arg) == type({})
    " Dict is esp. for internal usage.
    " deepcopy() is a bottleneck.
    let Search = get(a:arg, 'deepcopy', 1) ? deepcopy(s:Search) : s:Search
    let Search.curr_lnum = get(a:arg, 'curr_lnum', 0)
    let Search.min_range = get(a:arg, 'min_range', 0)
    let Search.max_range = get(a:arg, 'max_range', 0)
    let Search.keep_cursor = get(a:arg, 'keep_cursor', 0)
  elseif type(a:arg) == type(1)
    let Search = deepcopy(s:Search)
    let Search.curr_lnum = a:arg
    let Search.min_range = 0
    let Search.max_range = 0
    let Search.keep_cursor = 0
  else
    echoerr 'Invalid argument:' string(a:000)
  endif

  let Search.corr_lnum = 0

  return Search
endfunction

function! s:GetIsLineToSkip() abort dict
  return self.is_line_to_skip
endfunction
let s:Search.GetIsLineToSkip = funcref('s:GetIsLineToSkip')

function! s:GetLnums() abort dict
  return [self.curr_lnum, self.corr_lnum]
endfunction
let s:Search.GetLnums = funcref('s:GetLnums')

function! s:GetIsReverse() abort dict
  return self.reverse
endfunction
let s:Search.GetIsReverse = funcref('s:GetIsReverse')

function! s:SetMinRange(num) abort dict
  let self.min_range = a:num
endfunction
let s:Search.SetMinRange = funcref('s:SetMinRange')
function! s:SetMaxRange(num) abort dict
  let self.max_range = a:num
endfunction
let s:Search.SetMaxRange = funcref('s:SetMaxRange')

function! s:SetKeepCursor() abort dict
  let self.keep_cursor = 1
endfunction
let s:Search.SetKeepCursor = funcref('s:SetKeepCursor')
function! s:UnsetKeepCursor() abort dict
  let self.keep_cursor = 0
endfunction
let s:Search.UnsetKeepCursor = funcref('s:UnsetKeepCursor')

function! s:_is_hl_group_to_skip() abort
  let hl_groups = s:get_config_as_filetype('hl_groups_to_skip')
  return synIDattr(synID(line('.'), col('.'), 0), 'name')
        \ =~? join(hl_groups, '\|')
endfunction

function! s:SearchPair() abort dict
  let save_view = winsaveview()

  let self.is_line_to_skip = 0
  exe self.curr_lnum
  norm! $
  if s:_is_hl_group_to_skip()
    " Note: It's too slow without this guard up to hl_group though this check
    " is too rough for a line which contains both codes and the hl_group.
    let self.is_line_to_skip = 1
    call winrestview(save_view)
    return
  endif

  call self.SearchPairDownwards()
  if self.corr_lnum < 1
    call self.SearchPairUpwards()
  endif

  if self.corr_lnum > 1 && !self.keep_cursor | return | endif
  call winrestview(save_view)
endfunction
let s:Search.SearchPair = funcref('s:SearchPair')

function! s:SearchPairDownwards() abort dict
  " do { // current line
  "   ...
  " } while (cond); // corresponding line

  let self.reverse = 1

  let line = getline(self.curr_lnum)
  call self._set_candidates()

  for c in self.candidates
    let pat_above = c[0]
    if line =~# pat_above
      let self.patterns = c
      call self._search_lnum_downwards()
    endif
  endfor

  return
endfunction
let s:Search.SearchPairDownwards = funcref('s:SearchPairDownwards')

function! s:SearchPairUpwards() abort dict
  " if (cond) { // corresponding line
  "   ...
  " } // current line

  let self.reverse = 0
  call self._search_outmost_pair()
  call self._search_lnum_upwards()
endfunction
let s:Search.SearchPairUpwards = funcref('s:SearchPairUpwards')

function! s:_search_lnum_downwards() abort dict
  let pat_above = self.patterns[0]
  let pat_below = self.patterns[-1]
  let flags_unmove_downward_exc = 'nWz'
  let lnum_below = searchpair(pat_above, '', pat_below,
        \ flags_unmove_downward_exc, 's:_is_hl_group_to_skip()')
  let self.corr_lnum = lnum_below
endfunction
let s:Search._search_lnum_downwards = funcref('s:_search_lnum_downwards')

function! s:_set_candidates() abort dict
  if self.reverse
    let self.candidates = s:get_config_as_filetype('pairs_reverse')
    return
  endif

  let self.candidates = s:get_config_as_filetype('pairs')

  if exists('b:_doppelganger_search_pairs')
        \ && b:_doppelganger_search_pairs isnot# self.candidates
    let self.candidates = b:_doppelganger_search_pairs
    return

  elseif exists('b:match_words')
    call extend(self.candidates, s:parse_matchwords())
    call sort(self.candidates, 's:sort_by_length_desc')
    let b:_doppelganger_search_pairs = self.candidates
  endif
endfunction
let s:Search._set_candidates = funcref('s:_set_candidates')

function! s:parse_matchwords() abort
  let pairs = split(b:match_words, '\\\@<!,')
  call filter(pairs, '!empty(v:val)')
  call map(pairs, 'split(v:val, ''\\\@<!:'')')
  call map(pairs, function('s:swap_atoms'))
  return pairs
endfunction

function! s:swap_atoms(_, pat) abort
  if a:pat[-1] !~# '\\\d'
    return a:pat
  endif

  let pat = a:pat
  let cnt = 0
  let pat_to_save = '\\(.\{-}\\)'
  while pat[-1] =~# '\\\d'
    " Sample from vim-closetag:
    " ['<\@<=\([^/][^ \t>]*\)\%(>\|$\|[ \t][^>]*\%(>\|$\)\)', '<\@<=/\1>']
    let cnt += 1
    let pat_atom = '\\'. cnt
    let save_match = matchstr(pat[0], pat_to_save)
    let pat[0] = substitute(pat[0], pat_to_save, pat_atom, 'e')
    let pat[len(pat) - 1] = substitute(pat[-1], pat_atom, save_match, 'e')
  endwhile
  return pat
endfunction

function! s:sort_by_length_desc(pair1, pair2) abort
  return len(a:pair2[0]) - len(a:pair1[0])
endfunction

function! s:_search_lnum_upwards() abort dict
  if len(self.patterns) < 2 | return | endif

  let pat_above = self.patterns[0]
  let pat_below = self.patterns[-1]
  let flags_mobile_upward_inc = 'cbW'
  let flags_mobile_upward_exc = 'bWz'

  " Set cursot onto the very outmost pair to call searchpair().
  call search(pat_below, flags_mobile_upward_inc)

  " searchpair() fails to parse line-continuation with 'c'-flag
  let lnum_above = searchpair(pat_above, '', pat_below,
        \ flags_mobile_upward_exc, 's:_is_hl_group_to_skip()')

  if lnum_above < self.curr_lnum - self.min_range
    let self.corr_lnum = lnum_above
  else
    let self.is_line_to_skip = 1
  endif
endfunction
let s:Search._search_lnum_upwards = funcref('s:_search_lnum_upwards')

function! s:_search_outmost_pair() abort dict
  let line = getline(self.curr_lnum)
  let self.patterns = []

  call self._set_candidates()
  for c in self.candidates
    let pat_below = c[-1]
    let pat_below_at_endOfLine = s:append_endOfLine_pattern(pat_below)
    let match = matchstr(line, pat_below_at_endOfLine)
    if len(match)
      let self.patterns = c
      return
    endif
  endfor
endfunction
let s:Search._search_outmost_pair = funcref('s:_search_outmost_pair')

function! s:append_endOfLine_pattern(pat) abort
  let separators_at_end = ',;'

  " Sample: to get correct pattern
  " $
  " \$
  let pat_at_end = ''
  if a:pat =~# '\\v'
    let pat_at_end = a:pat =~# '\\\@<!$$'
          \ ? ''
          \ : '['. separators_at_end .']?$'
  elseif a:pat =~# '\\V'
    let pat_at_end = a:pat =~# '\\$$'
          \ ? ''
          \ : '\['. separators_at_end .']\?\$'
  elseif a:pat =~# '\\M'
    let pat_at_end = a:pat =~# '\\\@<!$$'
          \ ? ''
          \ : '\['. separators_at_end .']\?$'
  elseif a:pat !~# '\\\@<!$$'
    let pat_at_end = '['. separators_at_end .']\?$'
  endif

  return a:pat . pat_at_end
endfunction

