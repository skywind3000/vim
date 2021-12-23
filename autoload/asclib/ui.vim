"======================================================================
"
" ui.vim - 
"
" Created by skywind on 2021/12/22
" Last Modified: 2021/12/22 22:02:17
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :

"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let g:asclib_ui = get(g:, 'asclib_ui', {})


"----------------------------------------------------------------------
" input
"----------------------------------------------------------------------
function! asclib#ui#input(prompt, text, name)
	if has_key(g:asclib_ui, 'input')
		return g:asclib_ui.input(a:prompt, a:text, a:name)
	endif
	call inputsave()
	try
		let t = input(a:prompt, a:text)
	catch /^Vim:Interrupt$/
		let t = ""
	endtry
	call inputrestore()
	return t
endfunc


"----------------------------------------------------------------------
" confirm
"----------------------------------------------------------------------
function! asclib#ui#confirm(msg, choices, default)
	if has_key(g:asclib_ui, 'confirm')
		return g:asclib_ui.confirm(a:msg, a:choices, a:default)
	endif
	call inputsave()
	try
		let hr = confirm(a:msg, choices, default)
	catch /^Vim:Interrupt$/
		let hr = 0
	endtry
	call inputrestore()
	return hr
endfunc


"----------------------------------------------------------------------
" inputlist
"----------------------------------------------------------------------
function! asclib#ui#inputlist(textlist)
	if has_key(g:asclib_ui, 'inputlist')
		return g:asclib_ui.inputlist(a:textlist)
	endif
	call inputsave()
	try
		let hr = inputlist(a:textlist)
	catch /^Vim:Interrupt$/
		let hr = -1
	endtry
	call inputrestore()
	return hr
endfunc


