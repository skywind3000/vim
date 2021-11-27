"======================================================================
"
" input.vim - 
"
" Created by skywind on 2021/11/27
" Last Modified: 2021/11/27 21:03:06
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :

"----------------------------------------------------------------------
" init
"----------------------------------------------------------------------
function! s:init_input_box(prompt, opts)
	let border = get(a:opts, 'border', g:quickui#style#border)
	let hwnd = {}
	let hwnd.w = get(a:opts, 'w', strdisplaywidth(a:prompt))
	let hwnd.h = 2
	let hwnd.w = (hwnd.w < 25)? 25 : hwnd.w
	let hwnd.image = [a:prompt, repeat(' ', hwnd.w)]
	let hwnd.bid = quickui#core#scratch_buffer('input', hwnd.image)
	let hwnd.opts = deepcopy(a:opts)
	let hwnd.opts.color = get(a:opts, 'color', 'QuickBG')
	let hwnd.opts.bordercolor = get(a:opts, 'bordercolor', 'QuickBorder')
	let title = ' Input '
	let back = quickui#utils#make_border(hwnd.w, hwnd.h, border, title, 1)
	let hwnd.back = back
	return hwnd
endfunc


"----------------------------------------------------------------------
" create input box object
"----------------------------------------------------------------------
function! s:vim_create_input(prompt, opts)
	let hwnd = s:init_input_box(a:prompt, a:opts)
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


