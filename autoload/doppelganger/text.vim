let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Text = {}
function! doppelganger#text#new(pair_info) abort
  let Text = deepcopy(s:Text)
  " TODO: make `Text` independent from pair_info.
  let Text = extend(Text, a:pair_info)
  return Text
endfunction

function! s:Text__read_contents() abort dict
  const Contents = self.is_reverse
        \ ? doppelganger#text#contents#new(self.corr_lnum)
        \ : doppelganger#text#contents#new(self.corr_lnum, self.curr_lnum)
  const contents = Contents.Read()
  return contents
endfunction
let s:Text.read_contents = funcref('s:Text__read_contents')

function! s:Text__compose_chunks(contents) abort dict
  let Components = doppelganger#text#components#new(
        \ self.curr_lnum,
        \ self.corr_lnum,
        \ )
  const chunks = Components.ComposeChunks(a:contents)
  return chunks
endfunction
let s:Text.compose_chunks = funcref('s:Text__compose_chunks')

function! s:Text__ComposeChunks() abort dict
  const contents = self.read_contents()
  const chunks = self.compose_chunks(contents)
  return chunks
endfunction
let s:Text.ComposeChunks = funcref('s:Text__ComposeChunks')

