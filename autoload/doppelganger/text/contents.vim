let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Contents = {}

function! doppelganger#text#contents#new(dict) abort
  let Contents = deepcopy(s:Contents)
  let Contents.curr_lnum = a:dict.curr_lnum
  let Contents.corr_lnum = a:dict.corr_lnum
  let Contents.is_reverse = a:dict.is_reverse
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
  let curr_lnum = self.curr_lnum
  let corr_lnum = self.corr_lnum

  if self.is_reverse
    let self.raw_contents = [getline(corr_lnum)]
    return
  endif

  const start = corr_lnum
  const end = curr_lnum
  let self.raw_contents = getline(start, end)
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

