"======================================================================
"
" mode.vim - 
"
" Created by skywind on 2024/02/23
" Last Modified: 2024/02/24 01:04
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h:h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')
let s:current = ''


"----------------------------------------------------------------------
" find files in: autoload/module/mode
"----------------------------------------------------------------------
function! s:find_script() abort
	let found = {}
	for fn in asclib#path#lookup('autoload/module/mode', '*.vim')
		let name = asclib#path#basename(fn)
		let main = asclib#path#splitext(name)[0]
		let found[main] = fn
	endfor
	return found
endfunc


"----------------------------------------------------------------------
" locate script path
"----------------------------------------------------------------------
function! s:locate_script(name) abort
	let test = printf('autoload/module/mode/%s.vim', a:name)
	let fn = findfile(test, &rtp)
	if fn == ''
		return ''
	endif
	let fn = fnamemodify(fn, ':p')
	let fn = substitute(fn, '\\', '/', 'g')
	return fn
endfunc


"----------------------------------------------------------------------
" switch mode
"----------------------------------------------------------------------
function! module#mode#switch(bang, name) abort
	if s:current != ''
		let pname = printf('module#mode#%s#quit', s:current)
		if exists('*' . pname)
			try
				call call(pname, [])
			catch
				call asclib#common#errmsg('ModeSwitch: ' . v:exception)
			endtry
		endif
		let s:current = ''
	endif
	if a:bang
		return 0
	endif
	let name = asclib#string#strip(a:name)
	let script = s:locate_script(name)
	if script == ''
		call asclib#common#errmsg('ModeSwitch: mode not found: ' . name)
		return -1
	endif
	exec 'source ' . fnameescape(script)
	let s:current = name
	let pname = printf('module#mode#%s#init', s:current)
	if exists('*' . pname)
		call call(pname, [])
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" return help text for current mode
"----------------------------------------------------------------------
function! module#mode#help() abort
	if s:current == ''
		return ''
	endif
	let pname = printf('module#mode#%s#help', s:current)
	if exists('*' . pname)
		return call(pname, [])
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" switch command
"----------------------------------------------------------------------
function! module#mode#cmd(bang, name) abort
	call module#mode#switch(a:bang, a:name)
	if s:current != ''
		let text = module#mode#help()
		if text != ''
			let msg = printf('[%s] %s', s:current, text)
		else
			let msg = printf('[%s] enabled', s:current)
		endif
		let opts = {'highlight': 'Special', 'mode': ''}
		call asclib#ui#notify(msg, opts)
	endif
endfunc


"----------------------------------------------------------------------
" get current mode name
"----------------------------------------------------------------------
function! module#mode#current() abort
	return s:current
endfunc


"----------------------------------------------------------------------
" list available modes
"----------------------------------------------------------------------
function! module#mode#list() abort
	let scripts = s:find_script()
	return keys(scripts)
endfunc



"----------------------------------------------------------------------
" command argument completion
"----------------------------------------------------------------------
function! module#mode#complete(ArgLead, CmdLine, CursorPos) abort
	let names = keys(s:find_script())
	return asclib#common#complete(a:ArgLead, a:CmdLine, a:CursorPos, names)
endfunc



"----------------------------------------------------------------------
" select mode from ui
"----------------------------------------------------------------------
function! module#mode#select() abort
	let names = module#mode#list()
	let index = asclib#ui#select('Select Mode', names)
	redraw
	if index > 0
		let name = names[index - 1]
		call module#mode#cmd(0, name)
		" echom printf('switch mode to %s', name)
	endif
endfunc



