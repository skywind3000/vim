"======================================================================
"
" input.vim - 
"
" Created by skywind on 2021/11/27
" Last Modified: 2021/11/27 23:13
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :

"----------------------------------------------------------------------
" init
"----------------------------------------------------------------------
function! s:init_input_box(prompt, opts)
	let border = get(a:opts, 'border', g:quickui#style#border)
	let hwnd = {}
	let hwnd.w = get(a:opts, 'w', strdisplaywidth(a:prompt) + 2)
	let hwnd.h = 2
	let hwnd.w = (hwnd.w < 25)? 25 : hwnd.w
	let hwnd.image = [a:prompt, repeat(' ', hwnd.w)]
	let hwnd.bid = quickui#core#scratch_buffer('input', hwnd.image)
	let hwnd.opts = deepcopy(a:opts)
	let hwnd.opts.color = get(a:opts, 'color', 'QuickBG')
	let hwnd.opts.bordercolor = get(a:opts, 'bordercolor', 'QuickBorder')
	let hwnd.border = border
	let title = ' Input '
	if g:quickui#core#has_nvim != 0
		let back = quickui#utils#make_border(hwnd.w, hwnd.h, border, title, 1)
		let hwnd.back = back
	endif
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
	let winid = popup_create(hwnd.image, opts)
	if has_key(a:opts, 'line') == 0 || has_key(a:opts, 'col') == 0
		call quickui#utils#center(winid)
	endif
	let opts = {'mapping':0, 'cursorline':0, 'drag':1}
	let opts.border = [0,0,0,0,0,0,0,0,0]
	if border > 0
		let opts.borderchars = quickui#core#border_vim(border)
		let opts.border = [1,1,1,1,1,1,1,1,1]
		let opts.close = 'button'
	endif
	let opts.padding = [0,1,0,1]
	if has_key(a:opts, 'title') && (a:opts.title != '')
		let opts.title = ' ' . a:opts.title . ' '
	endif
	let opts.filter = function('s:popup_filter')
	let opts.callback = function('s:popup_exit')
	let opts.resize = 0
	let opts.highlight = get(a:opts, 'color', 'QuickBG')
endfunc


"----------------------------------------------------------------------
" testing suit
"----------------------------------------------------------------------
if 1
	let opts = {}
	let hwnd = s:init_input_box('enter your name:', opts)
	for t in hwnd.back
		echo t
	endfor
endif


