function! s:set_prefix(sub, name) abort
  " Given: ([''], 'prefix')
  " Return: ['g:doppelganger#prefix', 'doppelganger_prefix']
  let plugin = 'doppelganger'
  let prefix = [plugin, a:sub, a:name]

  call filter(prefix, 'v:val !=# ""')

  let prefix_glogal = 'g:'. join(prefix, '#')
  let prefix_local = join(prefix, '_')

  return [prefix_glogal, prefix_local]
endfunction

function! doppelganger#util#get_config(sub, name, ...) abort
  " Given: ([''], 'prefix')
  " Return: get(b:, 'doppelganger_prefix', g:doppelganger#prefix)
  let [g_var, local_var] = s:set_prefix(a:sub, a:name)
  let namespace = (a:0 > 0 ? a:1 : 'b') .':' " `b:`, `w:`, `t:`, etc.
  return get({namespace}, local_var, {g_var})
endfunction

function! doppelganger#util#get_config_as_filetypes(sub, name, default) abort
  " Given: ([''], 'hl_groups_to_skip', [])
  " Return: `hl_groups_to_skip` as the following logic:
  "   if exists('b:doppelganger_hl_groups_to_skip')
  "     return get(b:, 'doppelganger_hl_groups_to_skip', [])
  "   endif
  "
  "   let hl_groups_to_skip = deepcopy(g:doppelganger#hl_groups_to_skip['_'])
  "   if has_key(g:doppelganger#hl_groups_to_skip, &ft)
  "     let hl_groups_to_skip += deepcopy(g:doppelganger#hl_groups_to_skip[&ft])
  "   endif
  "
  "   return pairs
endfunction
