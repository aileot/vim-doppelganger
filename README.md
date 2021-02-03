# vim-doppelganger

Doppelganger shows the corresponding lines of each pairs by vitualtexts.

## Requirements

Doppelganger requires Neovim 0.4.0 or above;
Vim has no compatibility with this plugin.

Check if `has('nvim-0.4.0')` returns `1`.

## Installation

Install the plugin using your favorite package manager

### For dein.vim

```vim
call dein#add('kaile256/vim-doppelganger')
```

If you set up dein to manage plugins in TOML,

```toml
[[plugin]]
repo = 'kaile256/vim-doppelganger'
```

This is recommended in lazy load:

```toml
[[plugin]]
repo = 'kaile256/vim-doppelganger'
on_event = 'BufRead'
#on_cmd = [
# 'Doppelganger',
#]
```

### Optional

Additional doppelgangers are said to haunt with `plugin/matchit` or
[andymass/vim-matchup](https://github.com/andymass/vim-matchup).

### Configuration

```vim
" default
let g:doppelganger#pairs = {
      \ '_': [
      \   ['{', '}[,;]\?'],
      \   ['(', ')[,;]\?'],
      \   ['\[', '\][,;]\?'],
      \   ],
      \ }

" default
let g:doppelganger#pairs_reverse = {
      \ '_': [
      \   ['\s*do {.*', '\s*}\s*while (.*).*'],
      \ ],
      \ }

" default: 0
" If you prefer manual use with :DoppelgangerToggle or other commands, comment
" out the config
" let g:doppelganger#ego#disable_autostart = 1

" default: 3
" Doppelganger appears in the range aroud cursor.  All the variables whose name
" contain 'ego' only affect ego feature, i.e., both `DoppelgangerUpdate` and
" `:DoppelgangerToggle` always ignores the value.
let g:doppelganger#ego#max_offset = 5

" default: 4
" Doppelganger only appears when the range of pairs is wider than the value.
" When the value is less than 1, doppelganger will always appear even when a
" pair is in the same line.
let g:doppelganger#ego#min_range_of_pairs = 0
```

For more detail and the other configurations, read
[doc/doppelganger.txt](https://github.com/kaile256/vim-doppelganger/blob/master/doc/doppelganger.txt).

## License

MIT

