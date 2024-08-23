" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" state.vim - state manager
"
" Created by skywind on 2022/12/24
" Last Modified: 2023/08/24 17:28
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:opts = {}
let s:path = []
let s:current = {}
let s:popup = 0
let s:vertical = 0
let s:position = ''
let s:screencx = 0
let s:screency = 0
let s:wincx = 0
let s:wincy = 0
let s:state = -1
let s:exit = 0
let s:prefix = ''


"----------------------------------------------------------------------
" translate key
"----------------------------------------------------------------------
let s:translate = {
			\ "\<c-j>" : "\<down>",
			\ "\<c-k>" : "\<up>",
			\ "\<PageUp>" : "\<up>",
			\ "\<PageDown>" : "\<down>",
			\ "\<left>" : "\<left>",
			\ "\<right>" : "\<right>",
			\ "\<up>" : "\<up>",
			\ "\<down>" : "\<down>",
			\ "\<c-h>" : "\<left>",
			\ "\<c-l>" : "\<right>",
			\ "\<bs>" : "\<left>",
			\ }


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
function! s:config(what) abort
	return navigator#config#get(s:opts, a:what)
endfunc


"----------------------------------------------------------------------
" init state
"----------------------------------------------------------------------
function! navigator#state#init(opts) abort
	let s:opts = navigator#config#init(a:opts)
	let s:prefix = get(a:opts, 'prefix', '')
	let s:state = 0
	let s:exit = 0
	let s:path = []
	return 0
endfunc


"----------------------------------------------------------------------
" open window
"----------------------------------------------------------------------
function! navigator#state#open_window() abort
	let s:popup = get(g:, 'quickui_navigator_popup', 0)
	let s:vertical = s:config('vertical')
	let s:position = navigator#config#position(s:config('position'))
	let s:screencx = &columns
	let s:screency = &lines
	call navigator#display#open(s:opts)
	let s:winsize = navigator#display#getsize()
	if s:vertical == 0
		let s:wincx = s:winsize.w
		let s:wincy = s:config('min_height')
	else
		let s:wincx = s:config('min_width')
		let s:wincy = s:winsize.h
	endif
	let hide_cursor = get(s:opts, 'hide_cursor', 1)
	if hide_cursor
		silent call navigator#display#hide_cursor()
	endif
	if s:state == 0
		let s:state = 1
	endif
	redraw
endfunc


"----------------------------------------------------------------------
" close window
"----------------------------------------------------------------------
function! navigator#state#close_window() abort
	if s:state == 1
		silent call navigator#display#close()
		let s:state = 0
	endif
	let hide_cursor = get(s:opts, 'hide_cursor', 1)
	if hide_cursor
		silent call navigator#display#show_cursor()
	endif
	noautocmd redraw
	echon ''
	noautocmd redraw
endfunc


"----------------------------------------------------------------------
" translate path elements from key to label
"----------------------------------------------------------------------
function! s:translate_path(path)
	let path = []
	if s:prefix != ''
		let t = navigator#charname#prefix_label(s:prefix)
		let path += [t]
	endif
	for p in a:path
		let t = navigator#charname#get_key_label(p)
		let path += [t]
	endfor
	return path
endfunc


"----------------------------------------------------------------------
" resize window to fit
"----------------------------------------------------------------------
function! navigator#state#resize(ctx) abort
	let ctx = a:ctx
	let padding = navigator#config#get(s:opts, 'padding')
	if s:vertical == 0
		let height = ctx.cy
		call navigator#display#resize(-1, height)
	else
		let width = ctx.cx
		call navigator#display#resize(width, -1)
	endif
endfunc


"----------------------------------------------------------------------
" select_window: return key array with keymap window
"----------------------------------------------------------------------
function! navigator#state#select_window(keymap, path) abort
	let keymap = navigator#config#visit(a:keymap, [])
	let ctx = navigator#config#compile(keymap, s:opts)
	if len(ctx.items) == 0
		return []
	endif
	call navigator#layout#init(ctx, s:opts, s:wincx, s:wincy)
	if ctx.pg_count <= 0
		return []
	endif
	let pg_count = ctx.pg_count
	let pg_size = ctx.pg_size
	let pg_index = 0
	call navigator#layout#fill_pages(ctx, s:opts)
	if s:vertical == 0
		call navigator#display#resize(-1, ctx.pg_height)
	endif
	let map = {}
	for key in ctx.keys
		let item = ctx.items[key]
		let code = item.code
		let map[code] = key
	endfor
	let path = s:translate_path(a:path)
	let context = navigator#config#fetch('context', {})
	let fallback = s:config('fallback')
	while 1
		let context.page = ctx.pages[pg_index]
		let context.index = pg_index
		call navigator#config#store('context', context)
		call navigator#state#resize(ctx)
		let info = {}
		let info.path = path
		let info.separator = s:config('icon_separator')
		let info.mode = s:config('display_path')
		let info.pg_index = pg_index
		let info.pg_count = pg_count
		call navigator#display#update(ctx.pages[pg_index].content, info)
		try
			let code = getchar()
		catch /^Vim:Interrupt$/
			let code = "\<C-C>"
		endtry
		let ch = (type(code) == v:t_number)? nr2char(code) : code
		if ch == "\<ESC>" || ch == "\<c-c>"
			let s:exit = 1
			return []
		elseif has_key(s:translate, ch)
			let newch = s:translate[ch]
			if newch == "\<down>"
				let pg_index += 1
				let pg_index = (pg_index >= pg_count)? 0 : pg_index
			elseif newch == "\<up>"
				let pg_index -= 1
				let pg_index = (pg_index < 0)? (pg_count - 1) : pg_index
			elseif newch == "\<left>"
				return []
			endif
		elseif has_key(map, ch)
			let key = map[ch]
			let item = ctx.items[key]
			if item.child == 0
				return [key]
			endif
			let km = navigator#config#visit(keymap, [key])
			let hr = navigator#state#select_window(km, a:path + [key])
			if hr != []
				return [key] + hr
			endif
			if s:exit != 0
				return []
			endif
		elseif fallback
			return [ch]
		endif
	endwhile
endfunc


"----------------------------------------------------------------------
" select_silent: return key array
"----------------------------------------------------------------------
function! navigator#state#select_silent(keymap, path) abort
	let keymap = navigator#config#visit(a:keymap, [])
	let ctx = navigator#config#compile(keymap, s:opts)
	let opts = s:opts
	let map = {}
	for key in ctx.keys
		let item = ctx.items[key]
		let code = item.code
		let map[code] = key
	endfor

	let path = s:translate_path(a:path)
	let fallback = s:config('fallback')
	let timeout = get(opts, 'timeout', -1)

	while timeout > 0
		let t = timeout
		while t > 0
			if getchar(1)
				let t = timeout
				break
			endif
			sleep 20m
			let t -= 20
		endwhile

		if t <= 0 | break | endif

		try
			let code = getchar()
		catch /^Vim:Interrupt$/
			let code = "\<C-C>"
		endtry

		let ch = (type(code) == v:t_number)? nr2char(code) : code
		if ch == "\<ESC>" || ch == "\<c-c>"
			let s:exit = 1
			return []
		elseif has_key(s:translate, ch)
			let newch = s:translate[ch]
			if newch == "\<left>"
				return []
			endif
		elseif has_key(map, ch)
			let key = map[ch]
			let item = ctx.items[key]
			if item.child == 0
				return [key]
			endif
			let km = navigator#config#visit(keymap, [key])
			let hr = navigator#state#select_silent(km, a:path + [key])
			if s:exit != 0
				return []
			elseif hr == []
				break
			else
				return [key] + hr
			endif
		elseif fallback
			return [ch]
		endif
	endwhile

	" open and init window opts first
	call navigator#state#open_window()
	let key_array = navigator#state#select_window(a:keymap, a:path)
	call navigator#state#close_window()

	return key_array
endfunc


"----------------------------------------------------------------------
" entry point of state machine
"----------------------------------------------------------------------
function! navigator#state#start(keymap, opts) abort
	let opts = deepcopy(a:opts)
	let hr = []
	if has_key(a:keymap, 'prefix')
		let opts.prefix = a:keymap['prefix']
	endif
	call navigator#state#init(opts)
	if get(s:opts, 'timeout', -1) <= 0
		call navigator#state#open_window()
		let hr = navigator#state#select_window(a:keymap, [])
		call navigator#state#close_window()
	else
		let hr = navigator#state#select_silent(a:keymap, [])
	endif
	return hr
endfunc



