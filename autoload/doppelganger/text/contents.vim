let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Contents = {}

function! doppelganger#text#contents#new(lnum, ...) abort
  let Contents = deepcopy(s:Contents)
  let Contents.range = a:0 ? [ a:lnum, a:1 ] : [ a:lnum ]
  return Contents
endfunction

function! s:Contents__Read() abort dict
  call self.read_in_pair()
  call self.trim_whitespaces()
  call self.join()
  return self.text
endfunction
let s:Contents.Read = funcref('s:Contents__Read')

function! s:Contents__read_in_pair() abort dict
  const range = self.range
  if len(range) < 2
    const below = range[0]
    let self.raw_contents = [ getline(below) ]
    return
  endif

  const above = range[0]
  const below = range[1]
  let self.raw_contents = getline(above, below)
endfunction
let s:Contents.read_in_pair = funcref('s:Contents__read_in_pair')

function! s:Contents__trim_whitespaces() abort dict
  let contents = map(deepcopy(self.raw_contents),
        \ 'substitute(v:val, ''^\s*\|\s*$'', "", "")')

  const compress_whitespaces = s:get_config('compress_whitespaces')
  if compress_whitespaces
    call map(contents, 'substitute(v:val, ''\s\{2,}'', " ", "g")')
  endif

  let self.contents = contents
endfunction
let s:Contents.trim_whitespaces = funcref('s:Contents__trim_whitespaces')

function! s:Contents__join() abort dict
  const shim = s:get_config('shim_to_join')
  let self.text = join(self.contents, shim)
endfunction
let s:Contents.join = funcref('s:Contents__join')

