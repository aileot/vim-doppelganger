call doppelganger#init#hl_group()

let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Text = {}
function! doppelganger#text#new(pair_info) abort
  let Text = deepcopy(s:Text)
  " TODO: make `Text` independent from pair_info.
  let Text = extend(Text, a:pair_info)
  return Text
endfunction

function! s:Text__read_contents() abort dict
  let Contents = self.is_reverse
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

  let [c_prefix, c_shim, c_ellipsis, c_suffix] = Components.make_up(self.is_reverse)

  let chunks = empty(c_prefix) ? [] : c_prefix

  let len_rest = Components.get_fillable_width()

  const len_shim     = Components.displaywidth(c_shim)
  const len_ellipsis = Components.displaywidth(c_ellipsis)

  const idx = self.is_reverse ? 1 : 0
  const hl_contents = s:get_config('hl_contents')[idx]
  const hl_text = hl_contents[0]

  let is_last_chunk = v:false
  for line in a:contents
    let pending_text = ''

    for char in split(line, '\zs')
      let len_pending = strdisplaywidth(char)
      if len_pending > len_rest - len_ellipsis
        let chunks += [[ pending_text, hl_text ]] + c_ellipsis
        let len_rest = -1
        break
      endif
      let len_rest -= len_pending
      let pending_text .= char
    endfor

    if len_rest < 0 | break | endif
    " TODO: manage len_rest at shim.
    let chunks += [[ pending_text, hl_text ]] + c_shim
    let len_rest -= len_shim
  endfor

  if empty(c_suffix)
    return chunks
  endif

  if len_rest > 0
    const spaces = repeat(' ', len_rest)
    let chunks += [[ spaces ]]
  endif

  let chunks += c_suffix
  return chunks
endfunction
let s:Text.compose_chunks = funcref('s:Text__compose_chunks')

function! s:Text__ComposeChunks() abort dict
  const contents = self.read_contents()
  if len(contents) < 1 | return | endif
  const chunks = self.compose_chunks(contents)
  return chunks
endfunction
let s:Text.ComposeChunks = funcref('s:Text__ComposeChunks')

