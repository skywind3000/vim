"======================================================================
"
" quickui_mode.vim - 
"
" Created by skywind on 2024/02/24
" Last Modified: 2024/02/24 19:13:33
"
"======================================================================

"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:has_popup = exists('*popup_create') && v:version >= 800
let s:has_floating = has('nvim-0.4')
let s:has_vim_820 = (has('nvim') == 0 && has('patch-8.2.1'))
let s:has_version = s:has_vim_820 || has('nvim-0.5.0')
let s:has_quickui = s:has_version && (s:has_popup || s:has_floating)


"----------------------------------------------------------------------
" setup
"----------------------------------------------------------------------
let g:asclib = get(g:, 'asclib', {})
let g:asclib.ui = get(g:asclib, 'ui', {})


"----------------------------------------------------------------------
" input
"----------------------------------------------------------------------
function! s:quickui_input(prompt, text, name) abort
	if a:name == ''
		return quickui#input#open(a:prompt, a:text)
	else
		return quickui#input#open(a:prompt, a:text, a:name)
	endif
endfunc


"----------------------------------------------------------------------
" confirm
"----------------------------------------------------------------------
function! s:quickui_confirm(msg, choices, default) abort
	let choice = quickui#confirm#open(a:msg, a:choices, a:default)
	return choice
endfunc


"----------------------------------------------------------------------
" inputlist
"----------------------------------------------------------------------
function! s:quickui_inputlist(textlist) abort
	if len(a:textlist) == 0
		return -1
	endif
	let msg = a:textlist[0]
	let choices = a:textlist[1:]
	let opts = {}
	let opts.title = msg
	let hr = quickui#tools#clever_inputlist(msg, choices, opts)
	if hr < 0
		return 0
	endif
	return hr + 1
endfunc


"----------------------------------------------------------------------
" select text
"----------------------------------------------------------------------
function! s:quickui_select(msg, textlist) abort
	let keymaps = '123456789abcdefimopqrstuvwxyz'
	let rows = []
	let size = strlen(keymaps)
	let index = 0
	for item in a:textlist
		let key = (index >= size)? ' ' : strpart(keymaps, index, 1)
		let text = "[" . ((key != ' ')? ('&' . key) : ' ') . "]\t"
		let text = text . ' ' . item 
		let rows += [text]
		let index += 1
	endfor
	let opts = {}
	let opts.title = a:msg
	" let opts.close = 'button'
	let choice = quickui#tools#clever_inputlist(a:msg, rows, opts)
	if choice < 0
		return 0
	endif
	return choice + 1
endfunc


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
function! module#drivers#install()
	let g:asclib.ui = {}
	if get(g:, 'quickui_disable', 0) == 0 && s:has_quickui
		let g:asclib.ui.input = function('s:quickui_input')
		let g:asclib.ui.confirm = function('s:quickui_confirm')
		let g:asclib.ui.inputlist = function('s:quickui_inputlist')
		let g:asclib.ui.select = function('s:quickui_select')
	endif
	return 0
endfunc



"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
if 0
	call module#drivers#install()
	let branch = -1
	let branch = 2
	if branch == 0
		let question = "What do you want ?"
		let choices = "&Apples\n&Oranges\n&Bananas"
		let choice = asclib#ui#confirm(question, choices, 2)
		echo choice
	elseif branch == 1
		let choices = ['Select color:', '1. red', '2. green', '3. blue']
		let choice = asclib#ui#inputlist(choices)
		echo choice
	elseif branch == 2
		let choices = ['red', 'green', 'blue']
		let choice = s:quickui_select('Select color:', choices)
		" let choice = asclib#ui#select('Select color:', choices)
		echo choice
	endif 
endif



