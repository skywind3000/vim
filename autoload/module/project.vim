"======================================================================
"
" project.vim - 
"
" Created by skywind on 2023/07/03
" Last Modified: 2023/07/03 15:43:47
"
"======================================================================


"----------------------------------------------------------------------
" init project and put .root in the current dir
"----------------------------------------------------------------------
function! module#project#init(force) abort
	let root = asclib#path#get_root('%', 0, 1)
	if root != '' && a:force == 0
		let t = printf('ERROR: project root already exists in %s', root)
		call asclib#common#errmsg(t)
	else
		let r = expand('%:p:h')
		let t = printf('Create project root in "%s" ?', r)
		let t = asclib#ui#confirm(t, "&Yes\n&No", 2)
		if t == 1
			let n = printf('%s/.root', r)
			if has('win32') || has('win64')
				let n = substitute(n, '/', '\\', 'g')
			endif
			call writefile([], n)
			call asclib#common#echo('', 'File created: ' . n)
		endif
	endif
endfunc


"----------------------------------------------------------------------
" get path
"----------------------------------------------------------------------
function! module#project#path(path) abort
	let r = asclib#path#get_root('%')
	let p = asclib#path#join(r, a:path)
	return asclib#path#normalize(p)
endfunc


"----------------------------------------------------------------------
" check exists
"----------------------------------------------------------------------
function! module#project#exists(path) abort
	let p = module#project#path(a:path)
	return asclib#path#exists(p)
endfunc


"----------------------------------------------------------------------
" open file
"----------------------------------------------------------------------
function! module#project#open(name) abort
	let p = module#project#path(a:name)
	call asclib#utils#file_switch(['-switch=useopen,auto', p])
endfunc


"----------------------------------------------------------------------
" open if exists
"----------------------------------------------------------------------
function! module#project#try_open(name) abort
	let p = module#project#path(a:name)
	if asclib#path#exists(p)
		call asclib#utils#file_switch(['-switch=useopen,auto', p])
	else
		call asclib#common#errmsg('ERROR: cannot open ' . p)
	endif
endfunc


