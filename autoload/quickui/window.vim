"======================================================================
"
" window.vim - 
"
" Created by skywind on 2021/12/08
" Last Modified: 2021/12/08 23:45
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :


"----------------------------------------------------------------------
" window class
"----------------------------------------------------------------------
let s:window = {}
let s:window.w = 1            " window width
let s:window.h = 1            " window height
let s:window.x = 1            " column starting from 0
let s:window.y = 1            " row starting from 0
let s:window.z = 10           " priority
let s:window.winid = -1       " window id
let s:window.dirty = 0        " need update buffer ?
let s:window.text = []        " text lines
let s:window.bid = -1         " allocated buffer id
let s:window.hide = 0         " visibility
let s:window.mode = 0         " mode: 0/created, 1/closed
let s:window.opts = {}        " creation options
let s:window.info = {}        " init environment


"----------------------------------------------------------------------
" internal 
"----------------------------------------------------------------------
let s:has_nvim = quickui#core#has_nvim


"----------------------------------------------------------------------
" prepare opts
"----------------------------------------------------------------------
function! s:window.__prepare_opts(textlist, opts)
	let opts = deepcopy(a:opts)
	let opts.x = get(a:opts, 'x', 1)
	let opts.y = get(a:opts, 'y', 1)
	let opts.z = get(a:opts, 'z', 10)
	let opts.w = get(a:opts, 'w', 1)
	let opts.h = get(a:opts, 'h', -1)
	let opts.hide = get(a:opts, 'hide', 0)
	let opts.wrap = get(a:opts, 'wrap', 0)
	let opts.color = get(a:opts, 'color', 'QuickBG')
	let opts.border = get(a:opts, 'border', 0)
	let self.opts = opts
	let self.bid = quickui#core#buffer_alloc()
	let self.dirty = 1
	let self.x = opts.x
	let self.y = opts.y
	let self.z = opts.z
	let self.w = (opts.w < 1)? 1 : (opts.w)
	let self.h = (opts.h < 1)? 1 : (opts.h)
	let self.hide = opts.hide
	let self.mode = 0
	if has_key(a:opts, 'padding')
		let self.opts.padding = a:opts.padding
	else
		let self.opts.padding = [0,0,0,0]
	endif
	let pad = self.opts.padding
	let self.opts.tw = self.w + pad[1] + pad[3]
	let self.opts.th = self.h + pad[0] + pad[2]
	let border = quickui#core#border_auto(self.opts.border)
	let self.info.has_border = (len(border) > 0)? 1 : 0
	if self.info.has_border != 0
		let self.opts.tw += 2
		let self.opts.th += 2
	endif
	call self.set_text(a:textlist)
	if opts.h < 0
		let opts.h = len(self.text)
	endif
	let cmd = []
	if has_key(opts, 'tabstop')
		let cmd += ['setl tabstop=' . get(opts, 'tabstop', 4)]
	endif
	if has_key(opts, 'list')
		let cmd += [(opts.list)? 'setl list' : 'setl nolist']
	else
		let cmd += ['setl nolist']
	endif
	if get(opts, 'number', 0) != 0
		let cmd += ['setl number']
	else
		let cmd += ['setl nonumber']
	endif
	let cmd += ['setl scrolloff=0']
	let cmd += ['setl signcolumn=no']
	if has_key(opts, 'syntax')
		let cmd += ['set ft=' . fnameescape(opts.syntax)]
	endif
	if has_key(opts, 'command')
		let command = opts.command
		if type(command) == type([])
			let cmd += command
		else
			let cmd += [''. command]
		endif
	endif
	if has_key(opts, 'cursorline')
		let need = (opts.cursorline)? 'cursorline' : 'nocursorlin'
		let cmd += ['setl ' . need]
	else
		let cmd += ['setl nocursorline']
	endif
	let cmd += ['setl nocursorcolumn nospell']
	let self.info.cmd = cmd
	let self.info.pending_cmd = []
	let self.info.border_winid = -1
	let self.info.border_bid = -1
endfunc


"----------------------------------------------------------------------
" win filter
"----------------------------------------------------------------------
function! s:popup_filter(winid, key)
endfunc


"----------------------------------------------------------------------
" create window in vim
"----------------------------------------------------------------------
function! s:window.__vim_create()
	let opts = {"hidden":1, "pos": 'topleft'}
	let opts.hidden = 1
	let opts.wrap = self.opts.wrap
	let opts.minwidth = self.w
	let opts.maxwidth = self.w
	let opts.minheight = self.h
	let opts.maxheight = self.h
	let opts.col = self.x + 1
	let opts.line = self.y + 1
	let opts.mapping = 0
	let opts.fixed = (opts.wrap == 0)? 1 : 0
	let opts.cursorline = get(self.opts, 'cursorline', 0)
	let opts.drag = get(self.opts, 'drag', 0)
	let opts.scrollbar = 0
	let opts.zindex = self.z + 1
	let self.winid = popup_create(self.bid, opts)
	let self.filter = function('s:popup_filter')
	let winid = self.winid
	let init = []
	let init += ['setlocal nonumber signcolumn=no scrolloff=0']
	call quickui#core#win_execute(winid, init, 1)
	let opts = {}
	let opts.highlight = self.opts.color
	let border = quickui#core#border_auto(self.opts.border)
	if len(border) > 0
		let opts.borderchars = border
		let opts.border = [1,1,1,1,1,1,1,1,1]
		let bc = get(self.opts, 'bordercolor', 'QuickBorder')
		let opts.borderhighlight = [bc, bc, bc, bc]
		if has_key(self.opts, 'title')
			let opts.title = self.opts.title
		endif
	endif
	if has_key(self.opts, 'padding') 
		let opts.padding = self.opts.padding
	endif
	call setwinvar(winid, '&wincolor', self.opts.color)
	call popup_setoptions(winid, opts)
	call quickui#core#win_execute(winid, self.info.cmd)
	let pc = self.info.pending_cmd
	if len(pc) > 0
		call quickui#core#win_execute(winid, pc)
		let self.info.pending_cmd = []
	endif
	if self.hide == 0
		call popup_show(winid)
	endif
endfunc


"----------------------------------------------------------------------
" create window in nvim
"----------------------------------------------------------------------
function! s:window.__nvim_create()
endfunc


"----------------------------------------------------------------------
" open window
"----------------------------------------------------------------------
function! s:window.open(textlist, opts)
	call self.close()
	call self.__prepare_opts(a:textlist, a:opts)
	if s:has_nvim == 0
		call self.__vim_create()
	else
		call self.__nvim_create()
	endif
	let self.mode = 1
endfunc



"----------------------------------------------------------------------
" close window
"----------------------------------------------------------------------
function! s:window.close()
	if self.winid >= 0
		if s:has_nvim == 0
			call popup_close(self.winid)
		else
			call nvim_win_close(self.winid, 1)
			if self.info.border_winid >= 0
				call nvim_win_close(self.info.border_winid, 1)
				let self.info.border_winid = -1
			endif
		endif
	endif
	let self.winid = -1
	if self.bid >= 0
		call quickui#core#buffer_free(self.bid)
		let self.bid = -1
	endif
	if has_key(self.info, 'border_bid')
		if self.info.border_bid >= 0
			call quickui#core#buffer_free(self.info.border_bid)
			let self.info.border_bid = -1
		endif
	endif
	let self.hide = 0
	let self.mode = 0
endfunc


"----------------------------------------------------------------------
" show the window
"----------------------------------------------------------------------
function! s:window.show(show)
	if self.mode == 0
		return
	elseif s:has_nvim == 0
		if a:show == 0
			if self.winid >= 0
				call popup_hide(self.winid)
			endif
		else
			if self.winid >= 0
				call popup_show(self.winid)
			endif
		endif
	else
	endif
	let self.hide = (a:show == 0)? 1 : 0
endfunc


"----------------------------------------------------------------------
" move window
"----------------------------------------------------------------------
function! s:window.move(x, y)
	let self.x = a:x
	let self.y = a:y
	if self.mode == 0
		return
	elseif s:has_nvim == 0
		if self.winid >= 0
			let opts = {}
			let opts.col = self.x + 1
			let opts.line = self.y + 1
			call popup_move(self.winid, opts)
		endif
	else
	endif
endfunc


"----------------------------------------------------------------------
" center window
"----------------------------------------------------------------------
function! s:window.center()
	let w = self.w
	let h = self.h
	if self.mode != 0
		let w = self.opts.tw
		let h = self.opts.th
	endif
	let x = (&columns - w) / 2
	let y = (&lines - h) / 2
	let limit1 = (&lines - 2) * 80 / 100
	let limit2 = (&lines - 2)
	if h + 8 < limit1
		let y = (limit1 - h) / 2
	else
		let y = (limit2 - h) / 2
	endif
	call self.move(x, y)
endfunc


"----------------------------------------------------------------------
" resize
"----------------------------------------------------------------------
function! s:window.resize(width, height)
	let ww = a:width
	let hh = a:height
	let self.w = ww
	let self.h = hh
endfunc


"----------------------------------------------------------------------
" execute commands
"----------------------------------------------------------------------
function! s:window.execute(cmdlist)
	if type(a:cmdlist) == v:t_string
		let cmd = split(a:cmdlist, '\n')
	else
		let cmd = a:cmdlist
	endif
	let winid = self.winid
	if winid >= 0
		let pc = self.info.pending_cmd
		if len(pc) > 0
			call quickui#core#win_execute(winid, pc)
			let self.info.pending_cmd = []
		endif
		if len(cmd) > 0
			call quickui#core#win_execute(winid, cmd)
		endif
	else
		if !has_key(self.info, 'pending_cmd')
			let self.info.pending_cmd = cmd
		else
			let self.info.pending_cmd += cmd
		endif
	endif
endfunc


"----------------------------------------------------------------------
" update text in buffer
"----------------------------------------------------------------------
function! s:window.update()
	if self.bid >= 0
		call quickui#core#buffer_update(self.bid, self.text)
	endif
endfunc


"----------------------------------------------------------------------
" set content
"----------------------------------------------------------------------
function! s:window.set_text(textlist)
	if type(a:textlist) == v:t_list
		let textlist = deepcopy(a:textlist)
	else
		let textlist = split(a:textlist, '\n', 1)
	endif
	let self.text = textlist
	call self.update()
endfunc


"----------------------------------------------------------------------
" set line
"----------------------------------------------------------------------
function! s:window.set_line(index, text, ...)
	let require = a:index + 1
	let refresh = (a:0 < 1)? 1 : (a:1)
	let update = 0
	if len(self.text) < require
		let self.text += repeat([''], require - len(self.text))
		let update = 1
	endif
	let self.text[a:index] = a:text
	if update != 0
		self.update()
	elseif refresh != 0
		let bid = self.bid
		let index = a:index
		if bid >= 0
			call setbufvar(bid, '&modifiable', 1)
			call setbufline(bid, index + 1, [a:text])
			call setbufvar(bid, '&modified', 0)
		endif
	endif
endfunc


"----------------------------------------------------------------------
" get line
"----------------------------------------------------------------------
function! s:window.get_line(index)
	if a:index >= len(self.text)
		return ''
	endif
	return self.text[a:index]
endfunc


"----------------------------------------------------------------------
" constructor
"----------------------------------------------------------------------
function! quickui#window#new()
	let obj = deepcopy(s:window)
	return obj
endfunc


