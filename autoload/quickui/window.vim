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
let s:window.text = []        " buffer id
let s:window.bid = -1         " allocated buffer id
let s:window.visible = 1      " visibility
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
	let self.opts = opts
	let self.bid = quickui#core#buffer_alloc()
	let self.dirty = 1
	let self.x = opts.x
	let self.y = opts.y
	let self.z = opts.z
	let self.w = opts.w
	let self.h = opts.h
	let self.visible = 0
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
	return 0
endfunc


"----------------------------------------------------------------------
" dtor
"----------------------------------------------------------------------
function! s:window.release()
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
endfunc


"----------------------------------------------------------------------
" constructor
"----------------------------------------------------------------------
function! quickui#window#new(opts)
	let obj = deepcopy(s:window)
	call obj.__init__(a:opts)
	return obj
endfunc


