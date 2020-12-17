let s:get_config_as_filetype =
      \ function('doppelganger#util#get_config_as_filetype', ['search'])

function! doppelganger#search#get_pair_info(lnum, ...) abort
  let flags = get(a:, 1, '')
  let min_range = get(a:, 2, 0)

  let save_view = winsaveview()

  " Jump to the line number
  exe a:lnum

  if flags =~# 'b'
    let info = s:get_leader_info(a:lnum, min_range)
  else
    let info = s:get_open_info(a:lnum, min_range)
  endif

  if flags =~# 'n' || get(info, 'curr_lnum', 0) == 0
    call winrestview(save_view)
  else
    exe info['curr_lnum']
  endif

  if !has_key(info, 'patterns')
    return {}

  elseif flags =~# 'b'
    let info.preceding = info.patterns[0]
    let info.following = info.patterns[1:]
    let info.reverse = 1
  else
    let info.preceding = info.patterns[:-1]
    let info.following = info.patterns[-1]
    let info.reverse = 0
  endif

  return info
endfunction

function! s:get_leader_info(lnum, min_range) abort
  " do { // leader
  "   ...
  " } while (cond); // follower

  let line = getline(a:lnum)
  let pairs = s:set_pairs_reverse()

  for p in pairs
    let leader = p[0]
    if line =~# leader
      let followers = p[1:]
      for f in followers
        let lnum = s:_search_leader_lnum(leader, f)
        return {
              \ 'corr_lnum': lnum,
              \ 'patterns': followers,
              \ }
      endfor
    endif
  endfor

  return {}
endfunction

function! s:get_open_info(lnum, min_range) abort
  " if (cond) { // open
  "   ...
  " } // close

  let the_pair = s:get_outmost_pair(a:lnum)

  return the_pair != []
        \ ? {
        \     'corr_lnum':   s:get_lnum_open(the_pair, a:min_range),
        \     'patterns':  the_pair,
        \   }
        \ : {}
endfunction

function! s:set_pairs_reverse() abort "{{{1
  let groups = s:get_config_as_filetype('pairs_reverse')
  return groups
endfunction

function! s:_search_leader_lnum(pat_leader, pat_follower) abort "{{{1
  let flags_unmove_downward_exc = 'nWz'
  let Skip_comments = 'doppelganger#highlight#_is_hl_group_to_skip()'
  let lnum_leader = searchpair(a:pat_leader, '', a:pat_follower,
        \ flags_unmove_downward_exc, Skip_comments)
  return lnum_leader
endfunction

function! s:set_pairs() abort "{{{1
  let pairs = s:get_config_as_filetype('pairs')

  if exists('b:_doppelganger_search_pairs')
    return pairs + b:_doppelganger_search_pairs

  elseif exists('b:match_words')
    let pairs += s:parse_matchwords()
    let pairs = sort(pairs, 's:sort_by_length_desc')
    let b:_doppelganger_search_pairs = pairs
  endif

  return pairs
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

function! s:get_lnum_open(pair_dict, min_range) abort
  let pat_open = a:pair_dict[0]
  let pat_close = a:pair_dict[-1]
  let flags_mobile_upward_inc = 'cbW'
  let flags_unmove_upward_exc = 'nbWz'
  let Skip_comments = 'doppelganger#highlight#_is_hl_group_to_skip()'

  norm! $
  let lnum_close = search(pat_close, flags_mobile_upward_inc)
  " searchpair() fails to parse line-continuation with 'c'-flag
  let lnum_open = searchpair(pat_open, '', pat_close,
        \ flags_unmove_upward_exc, Skip_comments)

  if lnum_open > lnum_close - a:min_range
    " Continue the while loop anyway.
    return 0
  endif

  return lnum_open
endfunction

function! s:get_outmost_pair(lnum) abort "{{{1
  let line = getline(a:lnum)
  let pairs = s:set_pairs()

  for p in pairs
    let pat_close = p[-1]
    let pat_close_at_endOfLine = s:append_endOfLine_pattern(pat_close)
    let match = matchstr(line, pat_close_at_endOfLine)
    if len(match)
      return p
    endif
  endfor

  return []
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

