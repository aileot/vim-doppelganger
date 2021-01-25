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

function! s:Component__complete_component(component) abort dict
  let component = deepcopy(a:component)
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

  let c_prefix   = s:get_config('prefix')[idx]
  let c_suffix   = s:get_config('suffix')[idx]
  let c_shim     = s:get_config('shim')[idx]
  let c_ellipsis = s:get_config('ellipsis')[idx]

  let c_prefix   = self.complete_component(c_prefix)
  let c_shim     = self.complete_component(c_shim)
  let c_ellipsis = self.complete_component(c_ellipsis)
  let c_suffix   = self.complete_component(c_suffix)

  let self.c_prefix = c_prefix
  let self.c_suffix = c_suffix

  return deepcopy([c_prefix, c_shim, c_ellipsis, c_suffix])
endfunction
let s:Components.make_up = funcref('s:Components__make_up')


function! s:Components__get_fillable_width() abort dict
  const line = getline(self.curr_lnum)
  " Add 1 for a space inserted before any virtual text starts.
  const len_prefix = self.displaywidth(self.c_prefix)
  const len_suffix = self.displaywidth(self.c_suffix)
  const len_reserved = strdisplaywidth(line . len_prefix . len_suffix) + 1

  const max_column_width = eval(s:get_config('max_column_width'))
  const fillable_width = max_column_width - len_reserved
  return fillable_width
endfunction
let s:Components.get_fillable_width = funcref('s:Components__get_fillable_width')


function! doppelganger#text#components#new(curr_lnum, corr_lnum) abort
  let Components = deepcopy(s:Components)

  let Components.curr_lnum  = a:curr_lnum
  let Components.corr_lnum  = a:corr_lnum

  return Components
endfunction

