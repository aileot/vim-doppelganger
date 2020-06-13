# vim-doppelganger

Doppelganger follows the end of pairs.

## Requirements

Doppelganger requires Neovim 0.3.2+;
Vim has no compatibility with this plugin.

Check if `exists('*nvim_buf_set_virtual_text')` returns `1`.

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
on_event = 'BufWinEnter'
#on_cmd = [
# 'DoppelgangerUpdate',
# 'DoppelgangerToggle',
# 'DoppelgangerEgoEnable',
# 'DoppelgangerEgoToggle',
#]
```

### Optional

Additional doppelgangers are said to haunt with `plugin/matchit` or
[andymass/vim-matchup](https://github.com/andymass/vim-matchup).

## License

MIT

