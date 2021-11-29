
hi! link QuickDefaultBackground Pmenu
hi! link QuickDefaultSel PmenuSel
hi! link QuickDefaultKey Title
hi! link QuickDefaultDisable Comment
hi! link QuickDefaultHelp Conceal
hi! link QuickDefaultBorder Pmenu
hi! link QuickDefaultTermBorder Pmenu

if &background == 'dark'
	hi! QuickDefaultPreview ctermbg=237 guibg=#4c4846
else
	hi! QuickDefaultPreview ctermbg=12 guibg=#dddddd
endif


hi! QuickDefaultInput ctermfg=254 ctermbg=24 guifg=#e4e4e4 guibg=#005f87
hi! QuickDefaultCursor ctermfg=238 ctermbg=222 guifg=#444444 guibg=#ffd787
hi! QuickDefaultVisual ctermfg=31 ctermbg=255 guifg=#0087af guibg=#eeeeee

