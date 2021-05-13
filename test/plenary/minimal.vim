let s:script_path = expand('<sfile>:p')
let s:repo_root = fnamemodify(s:script_path, ':h:h:h')
exe 'set rtp+='. s:repo_root
exe 'set rtp+='. s:repo_root .'/../../nvim-lua/plenary.nvim'

filetype indent off
syntax off
set noswapfile
set nobackup
set nowritebackup

runtime plugin/plenary.vim
runtime plugin/doppelganger.vim
