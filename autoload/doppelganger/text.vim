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

function! s:Text__define_components() abort dict
  call self.define_hlgroups()

  const prefix = s:get_config('prefix')
  const suffix = s:get_config('suffix')

  let self.prefix = self.replace_keywords(prefix)
  let self.suffix = self.replace_keywords(suffix)

  let self.shim     = s:get_config('shim_to_join')
  let self.ellipsis = s:get_config('ellipsis')
endfunction
let s:Text.define_components = funcref('s:Text__define_components')

function! s:Text__define_hlgroups() abort dict
  let idx = self.is_reverse ? 1 : 0
  for component in ['prefix', 'contents', 'shim', 'ellipsis', 'suffix']
    let self['hl_'. component] = s:get_config('hl_'. component)[idx]
  endfor
endfunction
let s:Text.define_hlgroups = funcref('s:Text__define_hlgroups')

function! s:Text__detect_fillable_width() abort dict
  const line = getline(self.curr_lnum)
  " Add 1 for a space inserted before any virtual text starts.
  const len_reserved = strdisplaywidth(line . self.prefix . self.suffix) + 1
  const max_column_width = eval(s:get_config('max_column_width'))

  const fillable_width = max_column_width - len_reserved
  return fillable_width
endfunction
let s:Text.detect_fillable_width = funcref('s:Text__detect_fillable_width')

function! s:Text__replace_keywords(text) abort dict
  const abs = self.corr_lnum
  const rel = abs(self.curr_lnum - self.corr_lnum)
  const size = rel + 1

  let text = a:text
  let text = substitute(text, '<absolute>', abs, 'g')
  let text = substitute(text, '<relative>', rel, 'g')
  let text = substitute(text, '<size>', size, 'g')
  return text
endfunction
let s:Text.replace_keywords = funcref('s:Text__replace_keywords')

function! s:Text__compose_chunks(contents) abort dict
  call self.define_components()

  const ellipsis = g:doppelganger#text#ellipsis
  const len_ellipsis = strdisplaywidth(ellipsis)

  let len_rest = self.detect_fillable_width()

  if self.prefix is# ''
    let chunks = []
  else
    const c_prefix = [[self.prefix, self.hl_prefix]]
    let chunks = c_prefix
  endif

  const shim = s:get_config('shim_to_join')
  const hl_shim = self.hl_shim
  const len_shim = strdisplaywidth(shim)

  const hl_text = self.hl_contents
  let is_last_chunk = v:false
  for line in a:contents
    let pending_text = ''

    for char in split(line, '\zs')
      let len_pending = strdisplaywidth(char)
      if len_pending > len_rest - len_ellipsis
        let len_rest -= len_ellipsis
        let chunks += [[pending_text, hl_text], [self.ellipsis, self.hl_ellipsis]]
        let is_last_chunk = v:true
        break
      endif
      let len_rest -= len_pending
      let pending_text .= char
    endfor

    if is_last_chunk | break | endif
    " TODO: manage len_rest at shim.
    let chunks += [[pending_text, hl_text], [shim, hl_shim]]
    let len_rest -= len_shim
  endfor

  if self.suffix is# ''
    return chunks
  endif

  if len_rest > 0
    const spaces = repeat(' ', len_rest)
    let chunks += [[ spaces ]]
  endif

  const c_suffix = [[self.suffix, self.hl_suffix]]
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

