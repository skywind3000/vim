hi! link NonText Normal
hi LineNr guibg=bg
hi SignColumn guibg=bg

hi! LineNr term=bold guifg=#686868 guibg=NONE

if !has('gui_running')
	call module#colors#convert_gui_color()
endif


