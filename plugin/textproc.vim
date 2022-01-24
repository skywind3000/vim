"======================================================================
"
" textproc.vim - 
"
" Created by skywind on 2022/01/21
" Last Modified: 2022/01/21 19:41:14
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :


"----------------------------------------------------------------------
" script home
"----------------------------------------------------------------------
let s:script_home = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')
let s:scripts = {}


"----------------------------------------------------------------------
" script root
"----------------------------------------------------------------------
function! s:script_root()
	let location = get(g:, 'textproc_root', '')
	if location != ''
		return location
	endif
	let fn = s:script_home . '/site/text'
	let fn = substitute(fn, '\\', '\/', 'g')
	return fn
endfunc


"----------------------------------------------------------------------
" list script
"----------------------------------------------------------------------
function! s:script_list()
	let root = s:script_root()
	let filelist = globpath(root, '*', 1, 1)
	let select = {}
	let check = {}
	let marks = ['py', 'lua', 'pl']
	if s:windows == 0
		let marks += ['sh']
	else
		let marks += ['cmd', 'bat']
	endif
	for mark in marks
		let check[mark] = 1
	endfor
	call sort(filelist)
	for fn in filelist
		let name = fnamemodify(fn, ':t')
		let main = fnamemodify(fn, ':t:r')
		let ext = fnamemodify(name, ':e')
		let ext = (s:windows == 0)? ext : tolower(ext)
		if s:windows
			let fn = substitute(fn, '\/', '\\', 'g')
		endif
		if has_key(check, ext)
			let select[main] = fn
		endif
	endfor
	return select
endfunc

" echo s:script_list()

"----------------------------------------------------------------------
" run script
"----------------------------------------------------------------------
function! s:script_run(name, lnum, count, debug)
	if a:count <= 0
		return 0
	endif
	let scripts = s:script_list()
	return 0
endfunc


"----------------------------------------------------------------------
" function
"----------------------------------------------------------------------
function! s:TextProcess(bang, args, line1, line2, count)
	let location = get(g:, 'textproc_home', '')
	if location == ''
		location
	endif
endfunc


"----------------------------------------------------------------------
" command defintion
"----------------------------------------------------------------------
command! -bang -nargs=1 -range=0  TP
		\ call s:TextProcess('<bang>', <q-args>, <line1>, <line2>, <count>)


