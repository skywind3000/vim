"======================================================================
"
" gui.vim - 
"
" Created by skywind on 2020/02/21
" Last Modified: 2020/02/21 23:20:43
"
"======================================================================



"----------------------------------------------------------------------
" borders
"----------------------------------------------------------------------
function! termbox#gui#border_extract(pattern)
	let parts = ['', '', '', '', '', '', '', '', '', '', '']
	for idx in range(11)
		let parts[idx] = strcharpart(a:pattern, idx, 1)
	endfor
	return parts
endfunc


function! termbox#gui#border_convert(pattern)
	if type(a:pattern) == v:t_string
		let p = termbox#gui#border_extract(a:pattern)
	else
		let p = a:pattern
	endif
	let pattern = [ p[1], p[5], p[7], p[3], p[0], p[2], p[8], p[6] ]
	return pattern
endfunc


"----------------------------------------------------------------------
" border_style
"----------------------------------------------------------------------
let s:border_styles = {}

let s:border_styles[1] = termbox#gui#border_extract('+-+|-|+-+++')
let s:border_styles[2] = termbox#gui#border_extract('┌─┐│─│└─┘├┤')
let s:border_styles[3] = termbox#gui#border_extract('╔═╗║─║╚═╝╟╢')
let s:border_styles[4] = termbox#gui#border_extract('/-\|-|\-/++')

let s:border_ascii = termbox#gui#border_extract('+-+|-|+-+++')


"----------------------------------------------------------------------
" border install
"----------------------------------------------------------------------
function! termbox#gui#border_install(name, pattern)
	let s:border_styles[a:name] = termbox#gui#border_extract(a:pattern)
endfunc


"----------------------------------------------------------------------
" border get
"----------------------------------------------------------------------
function! termbox#gui#border_get(name)
	if has_key(s:border_styles, a:name)
		return s:border_styles[a:name]
	endif
	return s:border_ascii
endfunc


"----------------------------------------------------------------------
" border vim
"----------------------------------------------------------------------
function! termbox#gui#border_vim(name)
	let border = termbox#gui#border_get(a:name)
	return termbox#gui#border_convert(border)
endfunc


"----------------------------------------------------------------------
" make border
"----------------------------------------------------------------------
function! termbox#gui#make_border(width, height, border, title, button)
	let pattern = termbox#gui#border_get(a:border)
	let image = []
	let w = a:width
	let h = a:height
	let text = pattern[0] . repeat(pattern[1], w) . pattern[2]
	let image += [text]
	let index = 0
	while index < h
		let text = pattern[3] . repeat(' ', w) . pattern[5]
		let image += [text]
		let index += 1
	endwhile
	let text = pattern[6] . repeat(pattern[7], w) . pattern[8]
	let image += [text]
	let text = image[0]
	let title = termbox#lib#string_fit(a:title, w)
	let text = termbox#lib#string_compose(text, 1, title)
	if a:button != 0
		let text = termbox#lib#string_compose(text, w + 1, 'X')
	endif
	let image[0] = text
	return image
endfunc


