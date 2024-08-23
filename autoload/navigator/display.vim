"======================================================================
"
" display.vim - 
"
" Created by skywind on 2023/06/26
" Last Modified: 2023/06/26 16:36:13
"
"======================================================================


"----------------------------------------------------------------------
" internal variable
"----------------------------------------------------------------------
let s:popup = 0
let s:opts = {}
let s:screencx = &columns
let s:screency = &lines
let s:wincx = 0
let s:wincy = 0
let s:vertical = 0
let s:position = ''

let s:bid = -1
let s:previous_wid = -1
let s:working_wid = -1

let s:popup_main = {}
let s:popup_foot = {}
let s:popup_head = {}
let s:popup_split = {}
let s:popup_background = {}


"----------------------------------------------------------------------
" internal functions
"----------------------------------------------------------------------
function! s:config(what) abort
	return navigator#config#get(s:opts, a:what)
endfunc


"----------------------------------------------------------------------
" calculate
"----------------------------------------------------------------------
function! s:need_keep(vertical, position) abort
	let keep = 0
	if a:vertical == 0
		if index(['rightbelow', 'botright', 'rightbot'], a:position) >= 0
			let keep = (&splitbelow == 0)? 1 : 0
		else
			let keep = (&splitbelow != 0)? 1 : 0
		endif
	else
		if index(['rightbelow', 'botright', 'rightbot'], a:position) >= 0
			let keep = (&splitright == 0)? 1 : 0
		else
			let keep = (&splitright != 0)? 1 : 0
		endif
	endif
	return keep
endfunc


"----------------------------------------------------------------------
" window open
"----------------------------------------------------------------------
function! s:win_open() abort
	let opts = s:opts
	let vertical = s:config('vertical')
	let position = s:config('position')
	let min_height = s:config('min_height')
	let min_width = s:config('min_width')
	let s:previous_wid = winnr()
	let keep = s:need_keep(vertical, position)
	if keep
		call navigator#utils#save_view()
	endif
	if vertical == 0
		exec printf('%s %dsplit', position, min_height)
		exec printf('resize %d', min_height)
	else
		exec printf('%s %dvsplit', position, min_width)
		exec printf('vertical resize %d', min_width)
	endif
	if keep
		call navigator#utils#restore_view()
	endif
	let w:_navigator_keep = keep
	let s:working_wid = winnr()
	if s:bid < 0
		if exists('*bufadd')
			let s:bid = navigator#utils#create_buffer()
		else
			exec 'enew'
			let s:bid = bufnr('%')
			setlocal nobuflisted nomodifiable bufhidden=hide
		endif
	endif
	let bid = s:bid
	exec 'b ' . bid
	setlocal bt=nofile nobuflisted nomodifiable
	setlocal nowrap nonumber nolist nocursorline nocursorcolumn noswapfile
	if has('signs') && has('patch-7.4.2210')
		setlocal signcolumn=no 
	endif
	if has('spell')
		setlocal nospell
	endif
	if has('folding')
		setlocal fdc=0
	endif
	call navigator#utils#update_buffer(bid, [])
endfunc


"----------------------------------------------------------------------
" window close
"----------------------------------------------------------------------
function! s:win_close() abort
	if s:working_wid > 0
		let keep = get(w:, '_navigator_keep', 0)
		if keep
			silent call navigator#utils#save_view()
		endif
		exec printf('%dclose', s:working_wid)
		if keep
			silent call navigator#utils#restore_view()
		endif
		let s:working_wid = -1
		if s:previous_wid > 0
			silent exec printf('%dwincmd w', s:previous_wid)
			let s:previous_wid = -1
		endif
	endif
endfunc


"----------------------------------------------------------------------
" window resize
"----------------------------------------------------------------------
function! s:win_resize(width, height) abort
	if s:working_wid > 0
		let keep = get(w:, '_navigator_keep', 0)
		if keep
			call navigator#utils#save_view()
		endif
		call navigator#utils#window_resize(s:working_wid, a:width, a:height)
		if keep
			call navigator#utils#restore_view()
		endif
	endif
endfunc


"----------------------------------------------------------------------
" window get size
"----------------------------------------------------------------------
function! s:win_getsize() abort
	let size = {}
	let size.w = winwidth(0)
	let size.h = winheight(0)
	return size
endfunc


"----------------------------------------------------------------------
" window update
"----------------------------------------------------------------------
function! s:win_update(textline, info) abort
	let p = printf('page %d/%d', a:info.pg_index + 1, a:info.pg_count)
	if s:bid > 0
		call navigator#utils#update_buffer(s:bid, a:textline)
		if s:working_wid > 0 && s:working_wid == winnr()
			let t = ''
			if a:info.mode == 0
				let m = ' => '
				let t = join(a:info.path, m) . m
			endif
			let t .= ' %=(C-j/k: paging, BS: return, ESC: quit)'
			let &l:statusline = printf('Navigator (%s): %s', p, t)
			setlocal ft=navigator
		endif
	endif
endfunc


"----------------------------------------------------------------------
" window execute
"----------------------------------------------------------------------
function! s:win_execute(command) abort
	if type(a:command) == type([])
		let command = join(a:command, "\n")
	elseif type(a:command) == type('')
		let command = a:command
	else
		let command = a:command
	endif
	if s:working_wid > 0
		let wid = winnr()
		noautocmd exec printf('%dwincmd w', s:working_wid)
		exec command
		noautocmd exec printf('%dwincmd w', wid)
	endif
endfunc


"----------------------------------------------------------------------
" popup: open
"----------------------------------------------------------------------
function! s:popup_open() abort
	let position = s:config('popup_position')
	let border = s:config('popup_border')
	let min_height = s:config('min_height')
	let min_width = s:config('min_width')
	let opts = {}
	let opts.color = 'NavigaorPopup'
	let opts.bordercolor = opts.color
	let opts.z = 40
	if position == 'bottom'
		let opts.x = 0
		let opts.y = &lines - min_height - 2
		let opts.w = &columns
		let opts.h = min_height
	elseif position == 'top'
		let opts.x = 0
		let opts.y = 0
		let opts.w = &columns
		let opts.h = min_height
	else
		let opts.w = s:config('popup_width')
		let opts.h = s:config('popup_height')
		let opts.x = (&columns - opts.w) / 2
		let opts.y = (&lines * 4 / 5 - opts.h) / 2
		let opts.center = 1
		let opts.y = (opts.y < 1)? 1 : opts.y
	endif
	let s:popup_main = quickui#window#new()
	call s:popup_main.open([], opts)
	let s:popup_foot = quickui#window#new()
	let s:popup_head = quickui#window#new()
	let s:popup_background = quickui#window#new()
	let op = {}
	let op.w = opts.w
	let op.h = 1
	let op.z = 40
	if position == 'bottom'
		let op.x = 0
		let op.y = &lines - 2
		let op.color = 'NavigatorFoot'
		let op.bordercolor = op.color
		call s:popup_foot.open([], op)
		let op.y = &lines - 3 - min_height
		let op.color = 'NavigatorHead'
		let op.bordercolor = op.color
		call s:popup_head.open([], op)
	elseif position == 'top'
		let op.x = 0
		let op.y = opts.h + 1
		let op.color = 'NavigatorFoot'
		let op.bordercolor = op.color
		call s:popup_foot.open([], op)
		let op.y = 0
		let op.color = 'NavigatorHead'
		let op.bordercolor = op.color
		call s:popup_head.open([], op)
	else
		let op.x = s:popup_main.x
		let op.y = s:popup_main.y + s:popup_main.h
		" echom printf("%d/%d %d", opts.y, opts.h, op.y)
		let op.color = 'NavigatorFoot'
		let op.bordercolor = op.color
		call s:popup_foot.open([''], op)
		let op.y = s:popup_main.y - 1
		let op.color = 'NavigatorHead'
		let op.bordercolor = op.color
		call s:popup_head.open([''], op)
	endif
	if position == 'center' && border > 0
		let op = {}
		let op.w = s:popup_main.w + 2
		let op.h = s:popup_main.h + 4
		let op.x = s:popup_main.x - 1
		let op.y = s:popup_main.y - 1
		let op.z = 38
		let op.color = 'NavigatorBorder'
		let op.bordercolor = op.color
		let back = quickui#utils#make_border(op.w - 2, op.h - 2, border, '')
		call s:popup_background.open(back, op)
	endif
endfunc


"----------------------------------------------------------------------
" win: close
"----------------------------------------------------------------------
function! s:popup_close() abort
	let position = s:config('popup_position')
	call s:popup_main.close()
	call s:popup_foot.close()
	call s:popup_head.close()
	call s:popup_background.close()
endfunc


"----------------------------------------------------------------------
" resize
"----------------------------------------------------------------------
function! s:popup_resize(width, height) abort
	let position = s:config('popup_position')
	let border = s:config('popup_border')
	if position == 'bottom'
		call s:popup_main.resize(s:popup_main.w, a:height)
		call s:popup_main.move(0, &lines - a:height - 2)
		call s:popup_head.move(0, &lines - a:height - 3)
	elseif position == 'top'
		call s:popup_main.resize(s:popup_main.w, a:height)
		call s:popup_main.move(0, 1)
		call s:popup_foot.move(0, 1 + s:popup_main.h)
	else
		" call s:popup_main.resize(s:popup
		call s:popup_head.move(s:popup_main.x, s:popup_main.y - 1)
		call s:popup_foot.move(s:popup_main.x, s:popup_main.y + s:popup_main.h)
		if border > 0
			call s:popup_background.move(s:popup_main.x - 1, s:popup_main.y - 2)
		endif
	endif
	call s:popup_main.show(1)
	call s:popup_foot.show(1)
	call s:popup_head.show(1)
	if position == 'center' && border > 0
		call s:popup_background.show(1)
	endif
endfunc


"----------------------------------------------------------------------
" get size
"----------------------------------------------------------------------
function! s:popup_getsize() abort
	let size = {}
	let size.w = s:popup_main.w
	let size.h = s:popup_main.h
	return size
endfunc


"----------------------------------------------------------------------
" update content and statusline 
"----------------------------------------------------------------------
function! s:popup_update(content, info) abort
	let position = s:config('popup_position')
	let p = printf('page %d/%d', a:info.pg_index + 1, a:info.pg_count)
	call s:popup_main.set_text(a:content)
	call s:popup_main.execute('setlocal ft=navigator')
	let t = ''
	if a:info.mode == 0
		let t = join(a:info.path, ' => ') . ' => '
	endif
	let t = printf('Navigator (%s): %s', p, t)
	let r = '(C-j/k: paging, BS: return, ESC: quit)'
	if position == 'bottom'
		let w = s:popup_foot.w
		let size = strlen(t) + strlen(r)
		let t = t . repeat(' ', w - size) . r
		call s:popup_foot.set_text([t])
	else
		call s:popup_foot.set_text([t])
		let w = s:popup_foot.w
		let t = repeat(' ', w - strlen(r)) . r
		call s:popup_head.set_text([t])
	endif
endfunc


"----------------------------------------------------------------------
" execute command
"----------------------------------------------------------------------
function! s:popup_execute(command)
	call s:popup_main.execute(a:command)
endfunc


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
function! navigator#display#open(opts) abort
	let s:opts = a:opts
	let s:popup = s:config('popup')
	let s:vertical = s:config('vertical')
	let s:position = navigator#config#position(s:config('position'))
	let s:screencx = &columns
	let s:screency = &lines
	if s:popup == 0
		call s:win_open()
	else
		call s:popup_open()
	endif
	let size = navigator#display#getsize()
	if s:vertical == 0
		let s:wincx = size.w
		let s:wincy = s:config('min_height')
	else
		let s:wincx = s:config('min_width')
		let s:wincy = size.h
	endif
endfunc


"----------------------------------------------------------------------
" close 
"----------------------------------------------------------------------
function! navigator#display#close() abort
	if s:popup == 0
		silent call s:win_close()
	else
		silent call s:popup_close()
	endif
endfunc


"----------------------------------------------------------------------
" resize
"----------------------------------------------------------------------
function! navigator#display#resize(width, height) abort
	if s:popup == 0
		call s:win_resize(a:width, a:height)
	else
		call s:popup_resize(a:width, a:height)
	endif
endfunc


"----------------------------------------------------------------------
" get size
"----------------------------------------------------------------------
function! navigator#display#getsize() abort
	if s:popup == 0
		return s:win_getsize()
	else
		return s:popup_getsize()
	endif
endfunc


"----------------------------------------------------------------------
" update
"----------------------------------------------------------------------
function! navigator#display#update(content, info) abort
	if s:popup == 0
		call s:win_update(a:content, a:info)
	else
		call s:popup_update(a:content, a:info)
	endif
	noautocmd redraw
	if a:info.mode != 0
		let path = a:info.path
		let size = len(path)
		let sep = a:info.separator
		for name in path
			echohl NavigatorKey
			echon name
			echohl NavigatorSeparator
			echon ' ' . sep . ' '
		endfor
		echohl None
	endif
endfunc


"----------------------------------------------------------------------
" execute
"----------------------------------------------------------------------
function! navigator#display#execute(command) abort
	if s:popup == 0
		call s:win_execute(a:command)
	else
		call s:popup_execute(a:command)
	endif
endfunc


"----------------------------------------------------------------------
" hide cursor
"----------------------------------------------------------------------
function! navigator#display#hide_cursor()
	let s:t_ve = &t_ve
	let s:guicursor = &guicursor
	set t_ve=
	set guicursor=a:Normal
endfunc


"----------------------------------------------------------------------
" show cursor
"----------------------------------------------------------------------
function! navigator#display#show_cursor()
	if exists('s:t_ve')
		let &t_ve = s:t_ve
		let &guicursor = s:guicursor
	endif
endfunc


" vim: set ts=4 sw=4 tw=78 noet :

