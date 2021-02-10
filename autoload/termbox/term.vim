"======================================================================
"
" term.vim - 
"
" Created by skywind on 2020/02/21
" Last Modified: 2020/02/21 23:07:10
"
"======================================================================


"----------------------------------------------------------------------
" new term buffer
"----------------------------------------------------------------------
function! termbox#term#buf_new(cmd, opts)
	let [w, h] = termbox#manager#term_size(a:opts)
	if has('nvim') == 0
		let opts = {'hidden':1, 'term_rows':h, 'term_cols':h}
		let opts.term_kill = get(g:, 'termbox_kill', 'term')
		let opts.norestore = 1
		let opts.exit_cb = function('s:term_exit_vim')
		if has_key(a:opts, 'cwd')
			let opts.cwd = a:opts.cwd
		endif
		let bid = term_start(a:cmd, opts)
	else
		let bid = nvim_create_buf(v:false, v:true)
	endif
	if bid < 0
		return -1
	endif
	call setbufvar(bid, '&buflisted', 0)
	call setbufvar(bid, '&bufhidden', 1)
	let obj = termbox#lib#object(bid)
	let obj.bid = bid
	let obj.opts = deepcopy(a:opts)
	let obj.cmd = deepcopy(a:cmd)
	let obj.w = w
	let obj.h = h
	let obj.init = 0
	let obj.winid = -1
	return bid
endfunc


"----------------------------------------------------------------------
" check
"----------------------------------------------------------------------
function! termbox#term#buf_init(bid)
	let obj = termbox#lib#obj(a:bid)
	if type(obj) != t:v_dict
		return -1
	endif
	if !has_key(obj, 'init')
		return -2
	endif
	if obj.init != 0
		return 0
	endif
	if has('nvim') == 0

	else
		let opts = {'width':obj.w, 'height':obj.h}
		let opts.on_exit = function('s:term_exit_nvim')
		if has_key(obj.opts, 'cwd')
			let opts.cwd = obj.opts.cwd
		endif
		try
			call termopen(a:opts.cmd, opts)
		catch /.*/
			return -3
		endtry
	endif
	call termbox#manager#insert(obj.bid)
	let obj.init = 1
	return 0
endfunc

