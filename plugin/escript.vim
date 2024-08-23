" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" escript.vim - execute script
"
" Created by skywind on 2022/09/16
" Last Modified: 2022/09/16 23:59
"
"======================================================================

"----------------------------------------------------------------------
" script home
"----------------------------------------------------------------------
let s:script_home = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')
let s:scripts = {}


"----------------------------------------------------------------------
" string strip
"----------------------------------------------------------------------
function! s:string_strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)[\s\r\n]*$', '\1', '')
endfunc


"----------------------------------------------------------------------
" script root
"----------------------------------------------------------------------
function! s:script_roots() abort
	let candidate = []
	let fn = s:script_home . '/site/escript'
	let fn = substitute(fn, '\\', '\/', 'g')
	let candidate += [fn]
	let location = get(g:, 'escript_root', '')
	if location != ''
		if isdirectory(location)
			let candidate += [location]
		endif
	endif
	let rtp_name = get(g:, 'escript_home', 'escript')
	for rtp in split(&rtp, ',')
		if rtp != ''
			let path = rtp . '/' . rtp_name
			if isdirectory(path)
				let candidate += [path]
			endif
		endif
	endfor
	return candidate
endfunc


"----------------------------------------------------------------------
" list script
"----------------------------------------------------------------------
function! escript#list() abort
	let candidate = []
	let check = {}
	let select = {}
	for mark in ['vim', 'py']
		let check[mark] = 1
	endfor
	for root in s:script_roots()
		if isdirectory(root) == 0
			continue
		endif
		let candidate += [root]
		let test = root . '/' . (&filetype)
		if isdirectory(test)
			let candidate += [test]
		endif
	endfor
	for location in candidate
		let filelist = globpath(location, '*', 1, 1)
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
	endfor
	let methods = {}
	if exists('g:escript')
		for key in keys(g:escript')
			let methods[key] = g:escript[key]
		endfor
	endif
	if exists('b:escript')
		for key in keys(b:escript')
			let methods[key] = b:escript[key]
		endfor
	endif
	for key in keys(methods)
		if type(methods[key]) == v:t_string
			let value = methods[key]
			if value =~ '^:'
				let value = strpart(value, 1)
			endif
			let select[key] = function(value)
		else
			let select[key] = function(methods[key])
		endif
	endfor
	return select
endfunc

" echo escript#list()


"----------------------------------------------------------------------
" run script
"----------------------------------------------------------------------
function! escript#run(name)
	let scripts = escript#list()
	if has_key(scripts, a:name) == 0
		echohl ErrorMsg
		echo 'ERROR: escript not find: ' . a:name
		echohl None
		return 0
	endif
	if type(scripts[a:name]) == v:t_string
		let fn = scripts[a:name]
		let ext = fnamemodify(fn, ':e')
		if ext == 'vim'
			exec 'source ' . fnameescape(fn)
		elseif ext == 'py'
			exec 'pyxf ' . fnameescape(fn)
		endif
	elseif type(scripts[a:name]) == v:t_func
		call call(scripts[a:name], [])
	endif
endfunc


"----------------------------------------------------------------------
" command complete
"----------------------------------------------------------------------
function! s:complete(ArgLead, CmdLine, CursorPos)
	let candidate = []
	let scripts = escript#list()
	let names = keys(scripts)
	call sort(names)
	for name in names
		if stridx(name, a:ArgLead) == 0
			let candidate += [name]
		endif
	endfor
	return candidate
endfunc


"----------------------------------------------------------------------
" command definition
"----------------------------------------------------------------------
command! -nargs=1 -range=0 -complete=customlist,s:complete EScript
			\ call escript#run(<f-args>)


