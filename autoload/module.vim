"======================================================================
"
" module.vim - 
"
" Created by skywind on 2021/12/25
" Last Modified: 2021/12/25 23:29:44
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:script_name = expand('<sfile>:p')
let s:script_home = fnamemodify(s:script_name, ':h')
let s:module_home = substitute(s:script_home . '/module', '\\', '/', 'g')
let s:module_list = []
let s:module_load = []


"----------------------------------------------------------------------
" inter-modules
"----------------------------------------------------------------------
let g:module_plugin = []


"----------------------------------------------------------------------
" init module
"----------------------------------------------------------------------
function! s:module_load(name)
	let name = a:name
	let script = s:module_home . '/' . name . '.vim'
	let entry = 'module#' . name . '#init'
	if !filereadable(script)
		echohl ErrorMsg
		echom 'ERROR: file not readable ' . script
		echohl None
		return -1
	endif
	exec 'source ' . fnameescape(script)
	if exists('*' . entry) == 0
		echohl ErrorMsg
		echom 'ERROR: entry missing ' . entry . '()'
		echohl None
		return -2
	endif
	call call(entry, [])
	return 0
endfunc


"----------------------------------------------------------------------
" init module
"----------------------------------------------------------------------
function! module#init()
	let s:module_list = []
	let s:module_load = []
	let scripts = globpath(s:module_home, '*.vim', 1, 1)
	for name in scripts
		if filereadable(name)
			let name = fnamemodify(name, ':p:t:r')
			let s:module_list += [name]
		endif
	endfor
	if exists('g:module_load') == 0
		let s:module_load = deepcopy(s:module_list)
	else
		let avail = {}
		for name in s:module_list
			let avail[name] = 1
		endfor
		for name in g:module_load
			if has_key(avail, name)
				let s:module_load += [name]
			else
				echohl ErrorMsg
				echom 'ERROR: Module missing: ' . name
				echohl None
			endif
		endfor
	endif
	command! -nargs=1 ModuleLoad call s:module_load(<f-args>)
	for name in s:module_load
		exec 'ModuleLoad ' . fnameescape(name)
	endfor
	let g:ModuleLoaded = 1
endfunc



