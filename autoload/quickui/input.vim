"======================================================================
"
" input.vim - 
"
" Created by skywind on 2021/11/27
" Last Modified: 2021/11/28 03:52
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :

"----------------------------------------------------------------------
" internal variables
"----------------------------------------------------------------------
let s:has_nvim = g:quickui#core#has_nvim


"----------------------------------------------------------------------
" init
"----------------------------------------------------------------------
function! s:init_input_box(prompt, opts)
	let border = get(a:opts, 'border', g:quickui#style#border)
	let hwnd = {}
	let hwnd.h = 3
	if has_key(a:opts, 'w')
		let hwnd.w = a:opts.w
	else
		let limit = strdisplaywidth(a:prompt)
		if &columns >= 80
			let limit = (limit < 50)? 50 : limit
		endif
		let hwnd.w = limit
	endif
	let hwnd.image = [a:prompt, ' ', repeat(' ', hwnd.w)]
	let hwnd.bid = quickui#core#scratch_buffer('input', hwnd.image)
	let hwnd.opts = deepcopy(a:opts)
	let hwnd.opts.color = get(a:opts, 'color', 'QuickBG')
	let hwnd.opts.bordercolor = get(a:opts, 'bordercolor', 'QuickBorder')
	let hwnd.opts.text = get(a:opts, 'text', '')
	let hwnd.border = border
	let title = ' Input '
	if g:quickui#core#has_nvim != 0
		let back = quickui#utils#make_border(hwnd.w, hwnd.h, border, title, 1)
		let hwnd.back = back
	endif
	let hwnd.rl = quickui#readline#new()
	if hwnd.opts.text != ''
		call hwnd.rl.insert(hwnd.opt.text)
		call hwnd.rl.seek(0, 2)
		let hwnd.rl.select = 0
	endif
	let hwnd.pos = 0
	let hwnd.wait = 0
	let hwnd.exit = 0
	return hwnd
endfunc


"----------------------------------------------------------------------
" create input box object
"----------------------------------------------------------------------
function! s:vim_create_input(prompt, opts)
	let hwnd = s:init_input_box(a:prompt, a:opts)
	let opts = {'hidden':1, 'wrap':1}
	let opts.minwidth = hwnd.w
	let opts.maxwidth = hwnd.w
	let opts.minheight = hwnd.h
	let opts.minheight = hwnd.h
	let winid = popup_create(hwnd.bid, opts)
	if has_key(a:opts, 'line') == 0 || has_key(a:opts, 'col') == 0
		call quickui#utils#center(winid)
	endif
	let opts = {'mapping':0, 'cursorline':0, 'drag':1}
	let opts.border = [0,0,0,0,0,0,0,0,0]
	if hwnd.border > 0
		let opts.borderchars = quickui#core#border_vim(hwnd.border)
		let opts.border = [1,1,1,1,1,1,1,1,1]
		let opts.close = 'button'
	endif
	let opts.padding = [1,1,1,1]
	if has_key(a:opts, 'title') && (a:opts.title != '')
		let opts.title = ' ' . a:opts.title . ' '
	endif
	let bc = hwnd.opts.bordercolor
	let opts.resize = 0
	let opts.highlight = hwnd.opts.color
	let opts.borderhighlight = [bc, bc, bc, bc]
	let opts.callback = function('s:popup_exit')
	let hwnd.winid = winid
	let local = quickui#core#popup_local(winid)
	let local.hwnd = hwnd
	call popup_setoptions(winid, opts)
	call popup_show(winid)
	redraw
	return hwnd
endfunc


"----------------------------------------------------------------------
" exit callback
"----------------------------------------------------------------------
function! s:popup_exit(winid, code)
	let local = quickui#core#popup_local(a:winid)
	let local.hwnd.exit = 1
endfunc


"----------------------------------------------------------------------
" redraw input area
"----------------------------------------------------------------------
function! s:update_input(hwnd)
	let hwnd = a:hwnd
	let rl = hwnd.rl
	let size = hwnd.w
	let ts = float2nr(reltimefloat(reltime()) * 1000)
	let blink = rl.blink(ts)
	let blink = (hwnd.wait)? 0 : blink
	let hwnd.pos = rl.slide(hwnd.pos, size)
	let display = rl.render(hwnd.pos, size)
	let cmdlist = ['syn clear']
	let x = 1
	let y = 3
	let content = []
	for [attr, text] in display
		let len = strwidth(text)
		let content += [text]
		let color = 'QuickInput'
		if attr == 1
			let color = (blink == 0)? 'QuickCursor' : 'QuickInput'
		elseif attr == 2
			let color = 'QuickVisual'
		elseif attr == 3
			let color = (blink == 0)? 'QuickCursor' : 'QuickVisual'
		endif
		let cmd = quickui#core#high_region(color, y, x, y, x + len, 1)
		let cmdlist += [cmd]
		let x += len
	endfor
	let text = join(content, '')
	call setbufline(hwnd.bid, 3, text)
	call quickui#core#win_execute(hwnd.winid, cmdlist)
	redraw
	if 0
		echon 'blink='. blink 
		echon ' <'
		call rl.echo(blink, 0, hwnd.w) 
		echon '>'
	endif
endfunc


"----------------------------------------------------------------------
" create input box
"----------------------------------------------------------------------
function! quickui#input#create(prompt, opts)
	if s:has_nvim == 0
		let hwnd = s:vim_create_input(a:prompt, a:opts)
	else
	endif
	" let hwnd.wait = 1
	let rl = hwnd.rl
	let accept = 0
	let result = ''
	let rl.history += ['']
	let rl.history += ['5678']
	let rl.history += ['abcd']
	while hwnd.exit == 0
		noautocmd redraw
		call s:update_input(hwnd)
		try
			if hwnd.wait != 0
				let code = getchar()
			else
				let code = getchar(0)
			endif
		catch /^Vim:Interrupt$/
			let code = "\<C-C>"
		endtry
		let ch = (type(code) == v:t_number)? nr2char(code) : code
		if type(code) == v:t_number && code == 0
			try
				exec 'sleep 15m'
				continue
			catch /^Vim:Interrupt$/
				let code = "\<c-c>"
			endtry
		endif
		if ch == "\<ESC>" || ch == "\<c-c>"
			break
		endif
		if ch == ""
			continue
		elseif ch == "\<ESC>"
			break
		elseif ch == "\<cr>"
			let result = rl.update()
			let accept = 1
			call rl.history_save()
			break
		elseif ch == "\<LeftMouse>"
			let pos = getmousepos()
			if pos.winid == hwnd.winid
				if pos.line == 3
					let x = pos.column - 1
					if x >= 0 && x < hwnd.w
						let pos = rl.mouse_click(hwnd.pos, x)
						call rl.seek(pos, 0)
					endif
				endif
			endif
		else
			call rl.feed(ch)
		endif
	endwhile
	if s:has_nvim == 0
		call popup_close(hwnd.winid)
	else
	endif
	redraw
	return result
endfunc


"----------------------------------------------------------------------
" testing suit
"----------------------------------------------------------------------
if 1
	let opts = {}
	let opts.title = 'Input'
	" let opts.w = 50
	let hwnd = quickui#input#create('Enter your name:', opts)
endif


