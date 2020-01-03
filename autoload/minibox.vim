"======================================================================
"
" minibox.vim - 
"
" Created by skywind on 2020/01/01
" Last Modified: 2020/01/01 03:44:53
"
"======================================================================

function! s:nvim_context_create(textlist, opts)
	let border = get(a:opts, 'border', g:quickui#style#border)
	let hwnd = quickui#context#compile(a:textlist, border)
	let bid = nvim_create_buf(v:false, v:true)
	let hwnd.bid = bid
	let w = hwnd.width
	let h = hwnd.height
	let hwnd.index = get(a:opts, 'index', -1)
	let hwnd.opts = deepcopy(a:opts)
	let hwnd.current_win = nvim_get_current_win()
	call nvim_buf_set_lines(bid, 0, -1, hwnd.image)
	let opts = {'width':w, 'height':h, 'focusable':0, 'style':'minimal'}
	if has_key(a:opts, 'line') && has_key(a:opts, 'col')
		let opts.row = a:opts.line
		let opts.col = a:opts.col
	else
		let pos = quickui#core#around_cursor(w, h)
		let opts.row = pos[0]
		let opts.col = pos[1]
	endif
	let winid = nvim_open_win(buf, 0, opts)
	let hwnd.winid = winid
	let keymap = quickui#utils#keymap()
	let keymap['J'] = 'BOTTOM'
	let keymap['K'] = 'TOP'
	let hwnd.code = 0
	let hwnd.state = 1
	let hwnd.keymap = keymap
	let hwnd.hotkey = {}
	for item in hwnd.items
		if item.enable != 0 && item.key_pos >= 0
			let key = tolower(item.key_char)
			if get(a:opts, 'reserve', 0) == 0
				let hwnd.hotkey[key] = item.index
			else
				if key != 'h' && key != 'j' && key != 'k' && key != 'l'
					let hwnd.hotkey[key] = item.index
				endif
			endif
		endif
	endfor
	let hwnd.opts.color = get(a:opts, 'color', 'QuickBG')
    " optional: change highlight, otherwise Pmenu is used
    call nvim_win_set_option(win, 'winhl', 'Normal:'. hwnd.opts.color)
	redraw
	call getchar()
	call nvim_win_close(winid)
	return hwnd
endfunc


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
endif



