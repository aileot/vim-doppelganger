let s:Cache = {}

function! s:Cache__Detach() abort dict
  let self.lnum = 0
endfunction
let s:Cache.Detach = funcref('s:Cache__Detach')

function! s:Cache__Attach(lnum) abort dict
  let self.lnum = a:lnum
endfunction
let s:Cache.Attach = funcref('s:Cache__Attach')


function! s:Cache__fill_with_default(...) abort dict
  " '_': default value
  " '*': for all the states to the key
  const default = {
        \ 'lnum': 0,
        \ 'region': '*',
        \ 'name': '_',
        \ 'data': v:false,
        \ 'update_time': strftime('%T'),
        \ }

  let unit = get(a:, 1, {})
  let unit = extend(deepcopy(unit), default, 'keep')
  return unit
endfunction
let s:Cache.fill_with_default = funcref('s:Cache__fill_with_default')


function! s:Cache__drop(query) abort dict
  " Drop all the unmatched cache
  let q = self.fill_with_default(a:query)
  call filter(w:__doppelganger_cache, '
        \ v:val.lnum !~# q.lnum
        \ || v:val.region !~# q.region
        \ || v:val.name !~# q.name
        \ ')
endfunction
let s:Cache.drop = funcref('s:Cache__drop')

function! s:Cache__DropOutdated(queries) abort dict
  if !exists('w:__doppelganger_cache') | return | endif

  const default = {
        \ 'lnum': '.*',
        \ 'region': '.*',
        \ 'name': '.*',
        \ }
  for q in a:queries
    let q = extend(deepcopy(q), default, 'keep')
    call self.drop(q)
  endfor
endfunction
let s:Cache.DropOutdated = funcref('s:Cache__DropOutdated')


function! s:Cache__update(query) abort dict
  if !exists('w:__doppelganger_cache')
    let w:__doppelganger_cache = []
  endif

  const q = self.fill_with_default(a:query)
  call self.drop(q)
  let w:__doppelganger_cache += [ q ]
endfunction
let s:Cache.update = funcref('s:Cache__update')

function! s:Cache__Update(dict) abort dict
  if g:doppelganger#cache#disable
    return
  endif

  const default = {
        \ 'lnum': self.lnum,
        \ 'region': self.region,
        \ }
  let query = {}
  for name in keys(a:dict)
    let query.name = name
    let query.data = a:dict[name]
    call extend(query, default, 'keep')
    call self.update(query)
  endfor
endfunction
let s:Cache.Update = funcref('s:Cache__Update')


function! s:Cache__restore(query) abort dict
  if !exists('w:__doppelganger_cache')
    return v:null
  endif

  let q = self.fill_with_default(a:query)

  let units = w:__doppelganger_cache

  if len(units) is# 0
    return v:null
  endif

  for u in units
    if u.lnum isnot# q.lnum | continue | endif
    if u.region !~# q.region | continue | endif
    if u.name !~# q.name | continue | endif

    " Data should be unique in a cache at indices compared above.
    let data = u.data
    return data
  endfor

  return v:null
endfunction
let s:Cache.restore = funcref('s:Cache__restore')

function! s:Cache__Restore(name) abort dict
  if g:doppelganger#cache#disable
    return v:null
  endif

  let query = {
        \ 'region': self.region,
        \ 'lnum': self.lnum,
        \ 'name': a:name,
        \ }

  let data = self.restore(query)

  if data is# v:null
    return v:null
  endif

  return data
endfunction
let s:Cache.Restore = funcref('s:Cache__Restore')


function! s:Cache__clear() abort dict
  silent! unlet w:__doppelganger_cache
endfunction
let s:Cache.clear = funcref('s:Cache__clear')


function! doppelganger#cache#new(region) abort
  let Cache = deepcopy(s:Cache)
  let Cache.region = a:region
  let Cache.lnum = 0

  return Cache
endfunction

