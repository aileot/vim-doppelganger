call doppelganger#init#hl_group()

let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Components = {}

function! s:Components__replace_keywords(text) abort dict
  const abs = self.corr_lnum
  const rel = abs(self.curr_lnum - self.corr_lnum)
  const size = rel + 1

  let text = a:text
  let text = substitute(text, '{absolute}', abs,  'g')
  let text = substitute(text, '{relative}', rel,  'g')
  let text = substitute(text, '{size}',     size, 'g')
  return text
endfunction
let s:Components.replace_keywords = funcref('s:Components__replace_keywords')

function! s:Component__complete_component(name, idx) abort dict
  const template = deepcopy(s:get_config(a:name))
  const len = len(template)
  if len == 0
    return []
  endif

  let component = len == 1 ? template[0] : template[a:idx]

  try
    call map(component, '[ self.replace_keywords(v:val[0]), v:val[1] ]')
  catch /E684/
    const description = 'A component must be composed of `[string, hl_group]`'
    call doppelganger#debug#set_errormsg('component', description, component)
  endtry
  return component
endfunction
let s:Components.complete_component = funcref('s:Component__complete_component')


function! s:Components__displaywidth(component) abort dict
  const texts = map(deepcopy(a:component), 'v:val[0]')
  const line  = join(texts, '')
  const width = strdisplaywidth(line)
  return width
endfunction
let s:Components.displaywidth = funcref('s:Components__displaywidth')


function! s:Components__make_up() abort dict
  let idx = self.is_reverse ? 1 : 0

  let self.hl_contents = s:get_config('hl_contents')[idx]

  let chs_prefix   = self.complete_component('prefix',   idx)
  let chs_shim     = self.complete_component('shim',     idx)
  let chs_ellipsis = self.complete_component('ellipsis', idx)
  let chs_suffix   = self.complete_component('suffix',   idx)

  let self.chs_prefix   = chs_prefix
  let self.chs_shim     = chs_shim
  let self.chs_ellipsis = chs_ellipsis
  let self.chs_suffix   = chs_suffix

  let self.chunks = empty(chs_prefix) ? [] : chs_prefix

  return deepcopy([chs_prefix, chs_shim, chs_ellipsis, chs_suffix])
endfunction
let s:Components.make_up = funcref('s:Components__make_up')


function! s:Components__get_fillable_width() abort dict
  const line = getline(self.curr_lnum)
  const len_prefix = self.displaywidth(self.chs_prefix)
  const len_suffix = self.displaywidth(self.chs_suffix)
  " Add 1 for a space inserted before any virtual text starts.
  const len_reserved = strdisplaywidth(line) + len_prefix + len_suffix + 1

  const max_column_width = eval(s:get_config('max_column_width'))
  const fillable_width = max_column_width - len_reserved
  return fillable_width
endfunction
let s:Components.get_fillable_width = funcref('s:Components__get_fillable_width')


function! s:Components__append_chunks(len_fillable, chs_pending) abort dict
  const len_ellipsis = self.displaywidth(self.chs_ellipsis)
  let len_fillable = a:len_fillable

  for ch_pending in a:chs_pending
    let text_pending = ch_pending[0]
    let len_pending = strdisplaywidth(text_pending)

    if len_pending <= len_fillable - len_ellipsis
      let self.chunks += [ ch_pending ]
      let len_fillable -= len_pending
      continue
    endif

    let chars_pending = ''
    for char in split(text_pending, '\zs')
      let len_pending = strdisplaywidth(char)
      if len_pending <= len_fillable - len_ellipsis
        let chars_pending .= char
        let len_fillable -= len_pending
        continue
      endif

      let hl_group = ch_pending[1]
      let self.chunks += [[ chars_pending, hl_group ]] + self.chs_ellipsis
      let len_fillable = 0
      return len_fillable
    endfor

    if text_pending ==# ''
      throw '[doppelganger] The logics in this function contains some bugs'
    endif
  endfor

  return len_fillable
endfunction
let s:Components.append_chunks = funcref('s:Components__append_chunks')


function! s:Components__ComposeChunks(contents) abort dict
  const curr_lnum = self.curr_lnum
  const corr_lnum = self.corr_lnum

  const chs_shim   = self.chs_shim
  const chs_suffix = self.chs_suffix

  const idx = self.is_reverse ? 1 : 0
  const hl_contents = s:get_config('hl_contents')[idx]
  const hl_text = hl_contents[0]

  let len_fillable = self.get_fillable_width()
  let pending_lines = abs(curr_lnum - corr_lnum)

  for line in a:contents
    let chs_pending = [[ line, hl_text ]]
    let len_fillable = self.append_chunks(len_fillable, chs_pending)
    let pending_lines -= 1
    if pending_lines < 0 || len_fillable < 1 | break | endif
    let len_fillable = self.append_chunks(len_fillable, chs_shim)
  endfor

  if empty(chs_suffix)
    return self.chunks
  endif

  if len_fillable > 0
    const spaces = repeat(' ', len_fillable)
    let self.chunks += [[ spaces ]]
  endif

  let self.chunks += chs_suffix
  return self.chunks
endfunction
let s:Components.ComposeChunks = funcref('s:Components__ComposeChunks')


function! doppelganger#text#components#new(curr_lnum, corr_lnum) abort
  let Components = deepcopy(s:Components)

  let Components.curr_lnum  = a:curr_lnum
  let Components.corr_lnum  = a:corr_lnum
  let Components.is_reverse  = a:curr_lnum < a:corr_lnum

  call Components.make_up()

  return Components
endfunction

