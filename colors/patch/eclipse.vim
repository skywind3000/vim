
highlight NonText    gui=none guifg=#707070 guibg=bg

if !has('gui_running')
	set t_Co=256
	call module#colors#convert_gui_color()
endif


