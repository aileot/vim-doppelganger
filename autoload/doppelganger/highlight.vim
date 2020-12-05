let s:hl_group = 'DoppelgangerVirtualText'
let g:doppelganger#highlight#_pair = s:hl_group .'Pair'
let g:doppelganger#highlight#_pair_reverse = s:hl_group .'PairReverse'
exe 'hi def link' s:hl_group 'NonText'
exe 'hi def link' g:doppelganger#highlight#_pair s:hl_group
exe 'hi def link' g:doppelganger#highlight#_pair_reverse s:hl_group

let s:get_config_as_filetype =
      \ function('doppelganger#util#get_config_as_filetype', [''])

function! doppelganger#highlight#_is_hl_group_to_skip() abort
  let hl_groups = s:get_config_as_filetype('hl_groups_to_skip')
  return synIDattr(synID(line('.'), col('.'), 0), 'name')
        \ =~? join(hl_groups, '\|')
endfunction

