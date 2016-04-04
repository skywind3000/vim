if !exists('g:asclib#setting#config')
	let g:asclib#setting#config = {}
endif

let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h')

function! asclib#setting#get(key, default)
	return get(g:asclib#setting#config, a:key, a:default)
endfunc

function! asclib#setting#set(key, value)
	let g:asclib#setting#config[a:key] = a:value
endfunc

function! asclib#setting#update(dict)
	for key in keys(a:dict)
		let g:asclib#setting#config[key] = a:dict[key]
	endfor
endfunc

function! asclib#setting#script_home()
	return s:scripthome
endfunc

function! asclib#setting#has_windows()
	return has('win32') || has('win64') || has('win95') || has('win16')
endfunc


