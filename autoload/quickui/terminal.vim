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
" 
"----------------------------------------------------------------------

function! quickui#terminal#open(cmd, opts)
	let w = get(a:opts, 'w', 80)
	let h = get(a:opts, 'h', 24)
	let winid = -1
	let title = has_key(a:opts, 'title')? (' ' . a:opts.title .' ') : ''
	let border = get(a:opts, 'border', g:quickui#style#border)
	let button = (get(a:opts, 'close', '') == 'button')? 1 : 0
	let color = get(a:opts, 'color', 'QuickTerminal')
	if has('nvim') == 0
		let opts = {'hidden': 1, 'term_rows':h, 'term_cols':w}
		let opts.term_kill = get(a:opts, 'term_kill', 'term')
		let opts.norestore = 1
		let bid = term_start(a:cmd, opts)
		if bid <= 0
			return -1
		endif
		let opts = {'maxwidth':w, 'maxheight':h, 'minwidth':w, 'minheight':h}
		let opts.wrap = 0
		let opts.mapping = 0
		let opts.title = title
		let opts.close = (button)? 'button' : ''
		let opts.border = border? [1,1,1,1,1,1,1,1,1] : repeat([0], 9)
		let opts.highlight = color
		let opts.borderchars = quickui#core#border_vim(border)
		let opts.drag = get(a:opts, 'drag', 1)
		let opts.resize = 0
		let opts.callback = 'quickui#terminal#callback'
		let winid = popup_create(bid, opts)
		" call popup_move(opts)
		call popup_show(winid)
	else
	endif
	return winid
endfunc


function! quickui#terminal#callback(winid, code)
	echom "callback: ".a:winid. " code: ". a:code
endfunc


