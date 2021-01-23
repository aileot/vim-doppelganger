function! doppelganger#init#hl_group() abort
  hi def      DoppelgangerVirtualtextPrefix   ctermfg=243 guifg=#767676
  hi def      DoppelgangerVirtualtextContents ctermfg=64 guifg=#5f8700
  hi def link DoppelgangerVirtualtextShim     DoppelgangerVirtualtextPrefix
  hi def link DoppelgangerVirtualtextEllipsis DoppelgangerVirtualtextContents
  hi def link DoppelgangerVirtualtextSuffix   DoppelgangerVirtualtextPrefix

  hi def link DoppelgangerVirtualtextReversePrefix   DoppelgangerVirtualtextPrefix
  hi def      DoppelgangerVirtualtextReverseContents ctermfg=130 guifg=#df5f29
  hi def link DoppelgangerVirtualtextReverseShim     DoppelgangerVirtualtextShim
  hi def link DoppelgangerVirtualtextReverseEllipsis DoppelgangerVirtualtextEllipsis
  hi def link DoppelgangerVirtualtextReverseSuffix   DoppelgangerVirtualtextReversePrefix
endfunction

