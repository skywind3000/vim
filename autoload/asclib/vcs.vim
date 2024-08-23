"======================================================================
"
" vcs.vim - 
"
" Created by skywind on 2023/08/09
" Last Modified: 2023/08/09 16:06:05
"
"======================================================================


"----------------------------------------------------------------------
" root marker
"----------------------------------------------------------------------
let s:vcs_names = {
			\ 'svn': '.svn',
			\ 'git': '.git',
			\ 'csv': '.csv',
			\ }

let s:vcs_markers = []

for key in keys(s:vcs_names)
	call add(s:vcs_markers, s:vcs_names[key])
endfor


"----------------------------------------------------------------------
" get vcs root
"----------------------------------------------------------------------
function! asclib#vcs#root(where) abort
	let place = (a:where == '')? expand('%:p') : (a:where)
	return asclib#path#get_root(place, s:vcs_markers, 1)
endfunc


"----------------------------------------------------------------------
" get vcs type
"----------------------------------------------------------------------
function! asclib#vcs#type(where) abort
	let root = asclib#vcs#root(a:where)
	if root == ''
		return ''
	endif
	for key in keys(s:vcs_names)
		let t = asclib#path#join(root, s:vcs_names[key])
		if isdirectory(t)
			return key
		endif
	endfor
	return ''
endfunc


"----------------------------------------------------------------------
" confirm root type
"----------------------------------------------------------------------
function! asclib#vcs#croot(where, name) abort
	if !has_key(s:vcs_names, a:name)
		return ''
	endif
	let root = asclib#vcs#root(a:where)
	if root == ''
		return ''
	endif
	let test = asclib#path#join(root, s:vcs_names[a:name])
	if !isdirectory(test)
		return ''
	endif
	return root
endfunc


"----------------------------------------------------------------------
" git function
"----------------------------------------------------------------------
function! asclib#vcs#git(command, cwd)
	return asclib#core#system('git ' . a:command, a:cwd)
endfunc


"----------------------------------------------------------------------
" svn function
"----------------------------------------------------------------------
function! asclib#vcs#svn(command, cwd)
	return asclib#core#system('svn ' . a:command, a:cwd)
endfunc


"----------------------------------------------------------------------
" relative path
"----------------------------------------------------------------------
function! asclib#vcs#relpath(where)
	let place = (a:where == '')? expand('%:p') : (a:where)
	let root = asclib#vcs#root(place)
	if root == ''
		return ''
	endif
	return asclib#path#relpath(place, root)
endfunc


