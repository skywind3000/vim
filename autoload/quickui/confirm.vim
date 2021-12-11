"======================================================================
"
" confirm.vim - 
"
" Created by skywind on 2021/12/11
" Last Modified: 2021/12/11 21:02:59
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :


"----------------------------------------------------------------------
" calculate requirements
"----------------------------------------------------------------------
function! s:init(text, choices, index)
	let hwnd = {}
	let hwnd.text = quickui#utils#text_list_normalize(a:text)
	let hwnd.choices = quickui#utils#text_list_normalize(a:choises)
	let hwnd.items = []
	let hwnd.index = a:index
	let btn_size = 4
	for choice in hwnd.choices:
		let item = quickui#utils#item_parse(choice)
		let opts.items += [item]
		let width = item.text_width + 2
		let btn_size = (btn_size < width)? width : btn_size
	endfor
	let hwnd.btn_size = btn_size
	let text_width = 40
	for text in hwnd.text
		let ts = strdisplaywidth(text)
		let text_width = (text_width < ts)? ts : text_width
	endfor
	let hwnd.btn_width = (btn_size + 1) * len(hwnd.items)
	let hwnd.text_width = text_width
	let hwnd.w = (btn_width > text_width)? btn_width : text_width
	let hwnd.h = len(hwnd.text) + 2
	let hwnd.tw = hwnd.w + 4
	let hwnd.th = hwnd.h + 4
	return hwnd
endfunc


"----------------------------------------------------------------------
" main entry
"----------------------------------------------------------------------
function! quickui#confirm#open(text, choices, ...)
	let hwnd = s:init(text, choices, (a:0 < 1)? 0 : (a:1))
endfunc



