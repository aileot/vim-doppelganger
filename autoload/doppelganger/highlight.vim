let s:get_config_as_filetype =
      \ function('doppelganger#util#get_config_as_filetype', [''])

function! doppelganger#highlight#_is_hl_group_to_skip() abort
  let hl_groups = s:get_config_as_filetype('hl_groups_to_skip')
  return synIDattr(synID(line('.'), col('.'), 0), 'name')
        \ =~? join(hl_groups, '\|')
endfunction

