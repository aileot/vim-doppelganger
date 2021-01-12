let s:get_config_as_filetype =
      \ function('doppelganger#util#get_config_as_filetype', ['search'])

let s:Search = {}

function! doppelganger#search#new(curr_lnum) abort
  let Search = deepcopy(s:Search)
  let Search.curr_lnum = a:curr_lnum
  let Search.corr_lnum = 0
  return Search
endfunction

function! s:Search__SetIgnoredRange(num) abort dict
  let self.min_range = a:num
endfunction
let s:Search.SetIgnoredRange = funcref('s:Search__SetIgnoredRange')

function! s:Search__GetPairLnums() abort dict
  return [self.curr_lnum, self.corr_lnum]
endfunction
let s:Search.GetPairLnums = funcref('s:Search__GetPairLnums')

function! s:Search__IsReverse() abort dict
  return self.is_reverse
endfunction
let s:Search.IsReverse = funcref('s:Search__IsReverse')

function! s:Search__SearchPair() abort dict
  const min_range = self.min_range
  const curr_lnum = self.curr_lnum
  " Jump to the line number
  exe curr_lnum

  let info = s:get_leader_info(curr_lnum, min_range)
  let self.is_reverse = 1
  if get(info, 'corr_lnum', 0) is# 0
    let info = s:get_open_info(curr_lnum, min_range)
    let self.is_reverse = 0
  endif

  let self.corr_lnum = get(info, 'corr_lnum', 0)

  if !has_key(info, 'patterns')
    return {}
  endif

  return info
endfunction
let s:Search.SearchPair = funcref('s:Search__SearchPair')


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
        let corr_lnum = s:_search_leader_lnum(leader, f)
        return {
              \ 'corr_lnum': corr_lnum,
              \ 'patterns': followers,
              \ }
      endfor
    endif
  endfor

  return {}
endfunction

function! s:get_open_info(curr_lnum, min_range) abort
  " if (cond) { // open
  "   ...
  " } // close

  let pair = s:get_outmost_pair(a:curr_lnum)

  return pair != []
        \ ? {
        \     'corr_lnum':   s:get_lnum_open(pair, a:min_range),
        \     'patterns':  pair,
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

function! s:get_outmost_pair(curr_lnum) abort "{{{1
  let line = getline(a:curr_lnum)
  let pairs = s:set_pairs()

  for p in pairs
    let pat_close = p[-1]
    " Tips: appending <NL> matches as if '$' is, with any magics like '\v'.
    let match = matchstr(line ."\n", pat_close ."\n")
    if len(match)
      return p
    endif
  endfor

  return []
endfunction

