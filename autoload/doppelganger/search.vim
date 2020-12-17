let s:get_config_as_filetype =
      \ function('doppelganger#util#get_config_as_filetype', ['search'])

let s:Search = {}
function! doppelganger#search#new(lnum) abort
  let Search = deepcopy(s:Search)
  let Search.curr_lnum = a:lnum
  let Search.corr_lnum = 0
  let Search.min_range = 0
  let Search.max_range = 0
  let Search.keep_cursor = 0
  return Search
endfunction

function! s:Search.GetLnums() abort
  return [self.curr_lnum, self.corr_lnum]
endfunction

function! s:Search.GetIsReverse() abort
  return self.reverse
endfunction

function! s:Search.SetMinRange(num) abort
  let self.min_range = a:num
endfunction
function! s:Search.SetMaxRange(num) abort
  let self.max_range = a:num
endfunction

function! s:Search.SetKeepCursor() abort
  let self.keep_cursor = 1
endfunction
function! s:Search.UnsetKeepCursor() abort
  let self.keep_cursor = 0
endfunction

function! s:Search.SearchPair() abort
  let save_view = winsaveview()

  call self.SearchPairDownwards()
  if self.corr_lnum < 1
    call self.SearchPairUpwards()
  endif

  if self.corr_lnum > 1 && !self.keep_cursor | return | endif
  call winrestview(save_view)
endfunction

function! s:Search.SearchPairDownwards() abort
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

function! s:Search.SearchPairUpwards() abort
  " if (cond) { // corresponding line
  "   ...
  " } // current line

  let self.reverse = 0
  call self._search_outmost_pair()
  call self._search_lnum_upwards()
endfunction

function! s:Search._search_lnum_downwards() abort "{{{1
  let pat_above = self.patterns[0]
  let pat_below = self.patterns[-1]
  let flags_unmove_downward_exc = 'nWz'
  let Skip_comments = 'doppelganger#highlight#_is_hl_group_to_skip()'
  let lnum_below = searchpair(pat_above, '', pat_below,
        \ flags_unmove_downward_exc, Skip_comments)
  let self.corr_lnum = lnum_below
endfunction

function! s:Search._set_candidates() abort "{{{1
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

function! s:Search._search_lnum_upwards() abort
  if len(self.patterns) < 2 | return | endif

  let pat_above = self.patterns[0]
  let pat_below = self.patterns[-1]
  let flags_mobile_upward_inc = 'cbW'
  let flags_mobile_upward_exc = 'bWz'
  let Skip_comments = 'doppelganger#highlight#_is_hl_group_to_skip()'

  exe self.curr_lnum

  " Set cursot onto the very outmost pair to call searchpair().
  norm! $
  call search(pat_below, flags_mobile_upward_inc)

  " searchpair() fails to parse line-continuation with 'c'-flag
  let lnum_above = searchpair(pat_above, '', pat_below,
        \ flags_mobile_upward_exc, Skip_comments)

  if lnum_above < self.curr_lnum - self.min_range
    let self.corr_lnum = lnum_above
  endif
endfunction

function! s:Search._search_outmost_pair() abort "{{{1
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

function! s:append_endOfLine_pattern(pat) abort "{{{1
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

