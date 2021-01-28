let s:get_config = function('doppelganger#util#get_config', ['text'])

let s:Components = {}

function! s:Components__replace_keywords(text) abort dict
  const abs = self.corr_lnum
  const rel = abs(self.curr_lnum - self.corr_lnum)
  const size = rel + 1

  let text = a:text
  let text = substitute(text, '<absolute>', abs,  'g')
  let text = substitute(text, '<relative>', rel,  'g')
  let text = substitute(text, '<size>',     size, 'g')
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


function! s:Components__make_up(is_reverse) abort dict
  let idx = a:is_reverse ? 1 : 0

  let self.hl_contents = s:get_config('hl_contents')[idx]

  let c_prefix   = self.complete_component('prefix',   idx)
  let c_shim     = self.complete_component('shim',     idx)
  let c_ellipsis = self.complete_component('ellipsis', idx)
  let c_suffix   = self.complete_component('suffix',   idx)

  let self.c_prefix = c_prefix
  let self.c_suffix = c_suffix

  return deepcopy([c_prefix, c_shim, c_ellipsis, c_suffix])
endfunction
let s:Components.make_up = funcref('s:Components__make_up')


function! s:Components__get_fillable_width() abort dict
  const line = getline(self.curr_lnum)
  const len_prefix = self.displaywidth(self.c_prefix)
  const len_suffix = self.displaywidth(self.c_suffix)
  " Add 1 for a space inserted before any virtual text starts.
  const len_reserved = strdisplaywidth(line) + len_prefix + len_suffix + 1

  const max_column_width = eval(s:get_config('max_column_width'))
  const fillable_width = max_column_width - len_reserved
  return fillable_width
endfunction
let s:Components.get_fillable_width = funcref('s:Components__get_fillable_width')


function! s:Components__ComposeChunks(contents) abort dict
  const curr_lnum = self.curr_lnum
  const corr_lnum = self.corr_lnum

  const is_reverse = curr_lnum - corr_lnum < 0

  const [c_prefix, c_shim, c_ellipsis, c_suffix] = self.make_up(is_reverse)

  const len_shim     = self.displaywidth(c_shim)
  const len_ellipsis = self.displaywidth(c_ellipsis)

  const idx = is_reverse ? 1 : 0
  const hl_contents = s:get_config('hl_contents')[idx]
  const hl_text = hl_contents[0]

  let chunks = empty(c_prefix) ? [] : c_prefix
  let len_rest = self.get_fillable_width()
  let rest_lines = abs(curr_lnum - corr_lnum)

  for line in a:contents
    let pending_text = ''

    for char in split(line, '\zs')
      let len_pending = strdisplaywidth(char)
      if len_pending > len_rest - len_ellipsis
        let chunks += [[ pending_text, hl_text ]] + c_ellipsis
        let len_rest = -1
        break
      endif
      let pending_text .= char
      let len_rest -= len_pending
    endfor

    if len_rest < 0 | break | endif
    let chunks += [[ pending_text, hl_text ]]

    let rest_lines -= 1
    if rest_lines < 1 | break | endif
    let chunks += c_shim
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
let s:Components.ComposeChunks = funcref('s:Components__ComposeChunks')


function! doppelganger#text#components#new(curr_lnum, corr_lnum) abort
  let Components = deepcopy(s:Components)

  let Components.curr_lnum  = a:curr_lnum
  let Components.corr_lnum  = a:corr_lnum
  let Components.is_reverse  = a:curr_lnum < a:corr_lnum

  return Components
endfunction

