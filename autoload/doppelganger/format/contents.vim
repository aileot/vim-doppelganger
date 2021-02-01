let s:get_config = function('doppelganger#util#get_config', ['format'])

let s:Contents = {}

function! doppelganger#format#contents#new(lnum, ...) abort
  let Contents = deepcopy(s:Contents)
  let Contents.range = a:0 ? [ a:lnum, a:1 ] : [ a:lnum ]
  return Contents
endfunction

function! s:Contents__Read() abort dict
  const raw_contents = self.read_in_pair()
  if type(raw_contents) isnot# type([])
    return []
  endif
  const contents = self.trim_whitespaces(raw_contents)
  return contents
endfunction
let s:Contents.Read = funcref('s:Contents__Read')

function! s:Contents__read_in_pair() abort dict
  const range = self.range
  if len(range) < 2
    const below = range[0]
    const raw_contents = [ getline(below) ]
    return raw_contents
  endif

  const depth = s:get_config('contents_depth')
  if depth is# v:null
    return []
  endif

  const above = range[0]
  const below = depth > 0
        \ ? above + depth - 1
        \ : range[1] + depth

  if below < above
    return []
  endif

  const raw_contents = getline(above, below)
  return raw_contents
endfunction
let s:Contents.read_in_pair = funcref('s:Contents__read_in_pair')

function! s:Contents__trim_whitespaces(raw_contents) abort dict
  let contents = map(deepcopy(a:raw_contents),
        \ 'substitute(v:val, ''^\s*\|\s*$'', "", "")')

  const compress_whitespaces = s:get_config('compress_whitespaces')
  if compress_whitespaces
    call map(contents, 'substitute(v:val, ''\s\{2,}'', " ", "g")')
  endif

  return contents
endfunction
let s:Contents.trim_whitespaces = funcref('s:Contents__trim_whitespaces')

