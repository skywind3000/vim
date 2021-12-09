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


"----------------------------------------------------------------------
" internal 
"----------------------------------------------------------------------
let s:has_nvim = quickui#core#has_nvim


"----------------------------------------------------------------------
" prepare opts
"----------------------------------------------------------------------
function! s:window.__prepare_opts(opts)
	let opts = deepcopy(a:opts)
	let opts.x = get(a:opts, 'x', 1)
	let opts.y = get(a:opts, 'y', 1)
	let opts.z = get(a:opts, 'z', 10)
	let opts.w = get(a:opts, 'w', 1)
	let opts.h = get(a:opts, 'h', 1)
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
	let self.winid = popup_create(self.bid, opts)
	let self.filter = function('s:popup_filter')
	let winid = self.winid
	let init = []
	let init += ['setlocal nonumber signcolumn=no scrolloff=0']
	call win_execute(winid, init)
	let opts = {}
	let opts.color = self.opts.color
	let border = get(self.opts, 'border', g:quickui#style#border)
	let opts.border = [0,0,0,0,0,0,0,0,0]
	if type(border) == type('')
		if border == ''
			let bt = 0
		elseif border == '
	elseif type(border) == type(0)
	elseif type(border) == type([])
	endif
	call popup_setoptions(winid, opts)
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
function! s:window.open(opts)
	call self.close()
	call self.__prepare_opts(a:opts)
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
		endif
	endif
	let self.winid = -1
	if self.bid >= 0
		call quickui#core#buffer_free(self.bid)
		let self.bid = -1
	endif
	let self.hide = 0
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
" constructor
"----------------------------------------------------------------------
function! quickui#window#new()
	let obj = deepcopy(s:window)
	return obj
endfunc


