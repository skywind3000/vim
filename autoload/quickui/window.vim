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
let s:window.visible = 1      " visibility
let s:window.mode = 0         " mode: 0/invalid, 1/valid
let s:window.opts = {}        " creation options


"----------------------------------------------------------------------
" internal 
"----------------------------------------------------------------------
let s:has_nvim = quickui#core#has_nvim


"----------------------------------------------------------------------
" ctor
"----------------------------------------------------------------------
function! s:window.__init__(opts)
	let opts = deepcopy(a:opts)
	let opts.x = get(a:opts, 'x', 1)
	let opts.y = get(a:opts, 'y', 1)
	let opts.z = get(a:opts, 'z', 10)
	let opts.w = get(a:opts, 'w', 1)
	let opts.h = get(a:opts, 'h', 1)
	let opts.wrap = get(a:opts, 'wrap', 0)
	let opts.color = get(a:opts, 'color', 'QuickBG')
	let self.opts = opts
	let self.bid = quickui#core#buffer_alloc()
	let self.dirty = 1
	let self.x = opts.x
	let self.y = opts.y
	let self.z = opts.z
	let self.w = (opts.w < 1)? 1 : (opts.w)
	let self.h = (opts.h < 1)? 1 : (opts.h)
	let self.visible = 0
	let self.mode = 0
endfunc


"----------------------------------------------------------------------
" open window
"----------------------------------------------------------------------
function! s:window.open()
	call self.close()
	if s:has_nvim == 0
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
		let opts.cursorline = get(self.opts, 'cursorline', 0)
		let opts.drag = get(self.opts, 'drag', 0)
		let self.winid = popup_create(self.bid, opts)
		let winid = self.winid
		let init = []
		let init += ['setlocal nonumber signcolumn=no scrolloff=0']
		call win_execute(winid, init)
		call setwinvar(winid, '&wincolor', self.opts.color)
		call popup_show(winid)
	else
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
		endif
	endif
	let self.winid = -1
	let self.visible = 0
	let self.mode = 0
endfunc


"----------------------------------------------------------------------
" show the window
"----------------------------------------------------------------------
function! s:window.show()
	if self.winid >= 0
		if s:has_nvim == 0
			call popup_show(self.winid)
		else

		endif
		return 0
	endif
	let self.visible = 1
	return 0
endfunc


"----------------------------------------------------------------------
" dtor
"----------------------------------------------------------------------
function! s:window.release()
	call self.close()
	if self.bid >= 0
		call quickui#core#buffer_free(self.bid)
		let self.bid = -1
	endif
endfunc


"----------------------------------------------------------------------
" constructor
"----------------------------------------------------------------------
function! quickui#window#new(opts)
	let obj = deepcopy(s:window)
	call obj.__init__(a:opts)
	return obj
endfunc


