let s:windows = has('win32') || has('win64') || has('win95') || has('win16')

if has('gui_colors') == 0 && s:windows
	hi NonText ctermbg=19
	hi Normal ctermbg=19
endif

hi LineNr ctermfg=8 guifg=#808080
hi SignColumn ctermbg=NONE guibg=NONE gui=NONE cterm=NONE
hi NonText ctermfg=Gray guifg=Gray
hi StatusLineNC ctermbg=Gray guibg=Gray
hi VertSplit ctermbg=Gray guibg=Gray
hi TabLineFill ctermbg=Gray guibg=Gray

hi! Number ctermfg=6 guifg=#008080
hi! Keyword ctermfg=15 guifg=White
hi! Statement ctermfg=15 guifg=White
hi! Identifier ctermfg=Yellow guifg=Yellow
" hi! Constant ctermfg=6 guifg=#008080

