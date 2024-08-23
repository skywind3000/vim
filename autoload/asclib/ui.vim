"======================================================================
"
" ui.vim - 
"
" Created by skywind on 2021/12/22
" Last Modified: 2022/09/04 22:45
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :

"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let g:asclib = get(g:, 'asclib', {})
let g:asclib.ui = get(g:asclib, 'ui', {})


"----------------------------------------------------------------------
" input
"----------------------------------------------------------------------
function! asclib#ui#input(prompt, text, name) abort
	if has_key(g:asclib.ui, 'input')
		return g:asclib.ui.input(a:prompt, a:text, a:name)
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
function! asclib#ui#confirm(msg, choices, default) abort
	if has_key(g:asclib.ui, 'confirm')
		return g:asclib.ui.confirm(a:msg, a:choices, a:default)
	endif
	call inputsave()
	try
		let hr = confirm(a:msg, a:choices, a:default)
	catch /^Vim:Interrupt$/
		let hr = 0
	endtry
	call inputrestore()
	return hr
endfunc


"----------------------------------------------------------------------
" inputlist
"----------------------------------------------------------------------
function! asclib#ui#inputlist(textlist) abort
	if has_key(g:asclib.ui, 'inputlist')
		return g:asclib.ui.inputlist(a:textlist)
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


"----------------------------------------------------------------------
" select items
"----------------------------------------------------------------------
function! asclib#ui#select(msg, textlist) abort
	if len(a:textlist) == 0
		return -1
	endif
	if has_key(g:asclib.ui, 'select')
		return g:asclib.ui.select(a:msg, a:textlist)
	endif
	let textlist = [a:msg]
	let index = 0
	for item in a:textlist
		let textlist += [printf('%d - %s', index + 1, item)]
		let index += 1
	endfor
	call inputsave()
	try
		let hr = inputlist(textlist)
	catch
		return -1
	endtry
	return hr
endfunc


"----------------------------------------------------------------------
" notification
"----------------------------------------------------------------------
function! asclib#ui#notify(text, ...) abort
	let opts = (a:0 > 0)? a:1 : {}
	let mode = get(opts, 'mode', 'info')
	let text = a:text
	if has_key(g:asclib.ui, 'notify')
		return g:asclib.ui.notify(text, opts)
	endif
	let text = (mode == '')? text : printf('[%s] %s', mode, text)
	let pos = stridx(text, "\n")
	if pos >= 0
		let text = strpart(text, 0, pos)
	endif
	if exists('v:echospace')
		let echospace = v:echospace
	else
		let statusline = (&laststatus == 2)? 1 : 0
		let statusline = statusline || (&laststatus == 1 && winnr('$') > 1)
		let reqspaces_lastline = (statusline || !&ruler) ? 12 : 29
		let echospace = &columns - reqspaces_lastline
	endif
	let text = strpart(text, 0, echospace - 1)
	let high = ''
	if has_key(opts, 'highlight')
		let high = opts.highlight
	elseif mode == 'error'
		let high = 'ErrorMsg'
	elseif mode == 'info'
		let high = 'Normal'
	elseif mode == 'warn' || mode == 'warning'
		let high = 'WarningMsg'
	endif
	redraw
	if high != ''
		exec 'echohl ' . high
		echo text
		echohl None
	else
		echo text
	endif
endfunc


