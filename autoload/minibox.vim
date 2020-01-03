"======================================================================
"
" minibox.vim - 
"
" Created by skywind on 2020/01/01
" Last Modified: 2020/01/01 03:44:53
"
"======================================================================



if 1
	let lines = [
				\ "&New File\tCtrl+n",
				\ "&Open File\tCtrl+o", 
				\ ["&Close", 'test echo'],
				\ "--",
				\ "&Save\tCtrl+s",
				\ "Save &As",
				\ "Save All",
				\ "-",
				\ "&User Menu\tF9",
				\ "&Dos Shell",
				\ "~&Time %{&undolevels? '+':'-'}",
				\ "--",
				\ "E&xit\tAlt+x",
				\ "&Help",
				\ ]
	let opts = {}
	let opts.index = 2
	let opts.reserve = 1
	let opts.horizon = 1
	" let opts.border = 1
	echo quickui#context#nvim_popup(lines, opts)
endif



