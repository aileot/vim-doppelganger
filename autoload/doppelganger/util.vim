function! doppelganger#util#get_config(sub, name, ...) abort
  " Given ('', 'prefix')
  "   => get(b:, 'doppelganger_prefix', g:doppelganger#prefix)
  let plugin = 'doppelganger'
  let prefix = [plugin, a:sub, a:name]
  call filter(prefix, 'v:val !=# ""')
  let local_var = join(prefix, '_')
  let g_var = 'g:'. join(prefix, '#')

  let namespace = (a:0 > 0 ? a:1 : 'b') .':'
  return get({namespace}, local_var, {g_var})
endfunction

function! doppelganger#util#get_config_as_filetypes(sub, name, default) abort
  " Given: ([''], 'pairs', [])
  " Return:
  "   if exists('b:_doppelganger_pairs')
  "     return get(b:, 'doppelganger_pairs', []) + b:_doppelganger_pairs
  "   endif

  "   let pairs = deepcopy(g:doppelganger#pairs['_'])
  "   if has_key(g:doppelganger#pairs, &ft)
  "     let pairs += deepcopy(g:doppelganger#pairs[&ft])
  "   endif
endfunction
