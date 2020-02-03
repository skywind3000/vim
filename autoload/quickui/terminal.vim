"======================================================================
"
" terminal.vim - 
"
" Created by skywind on 2020/02/03
" Last Modified: 2020/02/03 10:31:33
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
" create a terminal popup
"----------------------------------------------------------------------
function! quickui#terminal#create(cmd, opts)
	let w = get(a:opts, 'w', 80)
	let h = get(a:opts, 'h', 24)
	let winid = -1
	let title = has_key(a:opts, 'title')? (' ' . a:opts.title .' ') : ''
	let border = get(a:opts, 'border', g:quickui#style#border)
	let button = (get(a:opts, 'close', '') == 'button')? 1 : 0
	let color = get(a:opts, 'color', 'QuickBG')
	let ww = w + ((border != 0)? 2 : 0)
	let hh = h + ((border != 0)? 2 : 0)
	let hwnd = {'opts':deepcopy(a:opts), 'code':-1}
	if !has_key(hwnd.opts, 'line')
		let limit1 = (&lines - 2) * 90 / 100
		let limit2 = (&lines - 2)
		if h + 4 < limit1
			let hwnd.opts.line = (limit1 - hh) / 2
		else
			let hwnd.opts.line = (limit2 - hh) / 2
		endif
		let hwnd.opts.line = (hwnd.opts.line < 1)? 1 : hwnd.opts.line
	endif
	if !has_key(hwnd.opts, 'col')
		let hwnd.opts.col = (&columns - ww) / 2
		let hwnd.opts.col = (hwnd.opts.col < 1)? 1 : hwnd.opts.col
	endif
	if has('nvim') == 0
		let opts = {'hidden': 1, 'term_rows':h, 'term_cols':w}
		let opts.term_kill = get(a:opts, 'term_kill', 'term')
		let opts.norestore = 1
		let opts.exit_cb = 'quickui#terminal#exit_cb'
		let opts.term_finish = 'close'
		let savedir = getcwd()
		if has_key(a:opts, 'cwd')
			call quickui#core#chdir(a:opts.cwd)
		endif
		let bid = term_start(a:cmd, opts)
		if has_key(a:opts, 'cwd')
			call quickui#core#chdir(savedir)
		endif
		if bid <= 0
			return -1
		endif
		let opts = {'maxwidth':w, 'maxheight':h, 'minwidth':w, 'minheight':h}
		let opts.wrap = 0
		let opts.mapping = 0
		let opts.title = title
		let opts.close = (button)? 'button' : 'none'
		let opts.border = border? [1,1,1,1,1,1,1,1,1] : repeat([0], 9)
		let opts.highlight = color
		let opts.borderchars = quickui#core#border_vim(border)
		let opts.drag = get(a:opts, 'drag', 1)
		let opts.resize = 0
		let opts.callback = 'quickui#terminal#callback'
		let winid = popup_create(bid, opts)
		call popup_move(winid, {'line':hwnd.opts.line, 'col':hwnd.opts.col})
		let hwnd.winid = winid
		let g:quickui#terminal#current = hwnd
		call popup_show(winid)
	else
	endif
	return hwnd
endfunc


"----------------------------------------------------------------------
" terminal exit_cb
"----------------------------------------------------------------------
function! quickui#terminal#exit_cb(job, message)
	if exists('g:quickui#terminal#current')
		let hwnd = g:quickui#terminal#current
		let hwnd.code = a:message
	endif
endfunc


"----------------------------------------------------------------------
" popup callback 
"----------------------------------------------------------------------
function! quickui#terminal#callback(winid, code)
	if exists('g:quickui#terminal#current')
		let hwnd = g:quickui#terminal#current
		let hwnd.winid = -1
		if has_key(hwnd, 'callback')
			let F = function(hwnd.callback)
			call F(code)
		endif
	endif
endfunc




