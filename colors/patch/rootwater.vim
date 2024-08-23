hi LineNr guibg=NONE
hi SignColumn guibg=NONE
hi SpecialKey guibg=NONE
" hi VertSplit guifg=#64645e guibg=#211f1c
hi VertSplit guifg=#e5e9f0 guibg=#3b4252 gui=NONE term=NONE
" hi VertSplit guifg=#e5e9f0 guibg=#4c566a

if !has('gui_running')
	call module#colors#convert_gui_color()
endif


