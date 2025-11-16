"======================================================================
"
" git.vim - 
"
" Created by skywind on 2025/11/16
" Last Modified: 2025/11/16 09:47:03
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win16') || has('win64') || has('win95')
let g:has_popup = exists('*popup_create') && v:version >= 800


"----------------------------------------------------------------------
" error message
"----------------------------------------------------------------------
function! gdv#git#errmsg(what)
	redraw
	echohl ErrorMsg
	echom 'ERROR: ' . a:what
	echohl None
endfunc


"----------------------------------------------------------------------
" system
"----------------------------------------------------------------------
function! gdv#git#system(cmd, cwd) abort
	let pwd = getcwd()
	if a:cwd != ''
		call quickui#core#chdir(a:cwd)
	endif
	let hr = quickui#utils#system(a:cmd)
	if a:cwd != ''
		call quickui#core#chdir(pwd)
	endif
	return hr
endfunc


"----------------------------------------------------------------------
" run git command and return output lines
"----------------------------------------------------------------------
function! gdv#git#run(args, cwd) abort
	return gdv#git#system('git ' . a:args, a:cwd)
endfunc


"----------------------------------------------------------------------
" get git root directory
"----------------------------------------------------------------------
function! gdv#git#root(where) abort
	let place = (a:where == '')? expand('%:p') : (a:where)
	let root = quickui#core#find_root(place, ['.git'], 1)
	if root == ''
		return ''
	endif
	let test = root . '/.git'
	if !isdirectory(test)
		return ''
	endif
	return root
endfunc


"----------------------------------------------------------------------
" get branch info
"----------------------------------------------------------------------
function! gdv#git#get_branch(where) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return ''
	endif
	let hr = gdv#git#run('branch', root)
	for text in split(hr, '\n')
		let text = quickui#core#string_strip(text)
		let name = matchstr(text, '^\*\s*\zs\S\+\ze\s*$')
		let name = quickui#core#string_strip(name)
		if name != ''
			return name
		endif
	endfor
	return ''
endfunc


