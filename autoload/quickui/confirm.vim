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
" build buttons
"----------------------------------------------------------------------
function! quickui#confirm#build_buttons(choices)
	let choices = quickui#utils#text_list_normalize(a:choices)
	let items = []
	let style = a:style
	let max_size = 4
	for choice in choices
		let item = quickui#utils#item_parse(choice)
		let items += [item]
		let width = item.text_width
		let max_size = (max_size < width)? width : max_size
	endfor
	for item in items
		let width = item.text_width
		let pad1 = (max_size - width) / 2
		let pad2 = max_size - width - pad1
		let item.text = repeat(' ', pad1) . item.text . repeat(' ', pad2)
		if item.key_pos >= 0
			let item.key_pos += pad1
		endif
		let item.text_width = strwidth(item.text)
	endfor
	return items
endfunc


"----------------------------------------------------------------------
" calculate requirements
"----------------------------------------------------------------------
function! s:init(text, choices, index, title)
	let hwnd = {}
	let hwnd.text = quickui#utils#text_list_normalize(a:text)
	let hwnd.items = quickui#confirm#build_buttons(choices, 0)
	let hwnd.index = a:index
	let btn_size = 4
	let button = ''
	let index = len(hwnd.items) - 1
	for item in hwnd.items
		let butten += ' '
		let button += ' ' . item.text . ' '
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
	let opts = {}
	let opts.w = hwnd.w
	let opts.h = hwnd.h
	let opts.border = g:quickui#style#border
	let opts.center = 1
	let opts.title = (a:title == '')? '' : (' ' . a:title . ' ')
	let hwnd.opts = opts
	let content = deepcopy(hwnd.text)
	let content += ['']
	let hwnd.content = content
	let hwnd.win = quickui#window#new()
	return hwnd
endfunc


"----------------------------------------------------------------------
" main entry
"----------------------------------------------------------------------
function! quickui#confirm#open(text, choices, ...)
	let index = (a:0 < 1)? 0 : (a:1)
	let title = (a:0 < 2)? '' : (a:2)
	let hwnd = s:init(text, choices, index, title)
endfunc



