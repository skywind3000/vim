"======================================================================
"
" core.vim - 
"
" Created by skywind on 2020/02/06
" Last Modified: 2020/02/06 00:24:48
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
" global
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let g:asclib#core#windows = s:windows
let g:asclib#core#has_nvim = has('nvim')


"----------------------------------------------------------------------
" get instance
"----------------------------------------------------------------------
function! asclib#core#instance(mode)
	if a:mode == 'buffer' || a:mode == 'buf' || a:mode == 'b:'
		if !exists('b:__asclib_core_instance__')
			let b:__asclib_core_instance__ = {}
		endif
		return b:__asclib_core_instance__
	elseif a:mode == 'tab' || a:mode == 'tabpage' || a:mode == 't:'
		if !exists('t:__asclib_core_instance__')
			let t:__asclib_core_instance__ = {}
		endif
		return t:__asclib_core_instance__
	elseif a:mode == 'win' || a:mode == 'window' || a:mode == 'w:'
		if !exists('w:__asclib_core_instance__')
			let w:__asclib_core_instance__ = {}
		endif
		return w:__asclib_core_instance__
	endif
	if !exists('s:__asclib_core_instance__')
		let s:__asclib_core_instance__ = {}
	endif
	return s:__asclib_core_instance__
endfunc


"----------------------------------------------------------------------
" safe change dir
"----------------------------------------------------------------------
function! asclib#core#chdir(path)
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	silent execute cmd . ' '. fnameescape(a:path)
endfunc


"----------------------------------------------------------------------
" safe input
"----------------------------------------------------------------------
function! asclib#core#input(prompt, text)
	call inputsave()
	try
		let t = input(a:prompt, a:text)
	catch /^Vim:Interrupt$/
		let t = "\<c-c>"
	endtry
	call inputrestore()
	return t
endfunc


"----------------------------------------------------------------------
" python simulate system() on window to prevent temporary window
"----------------------------------------------------------------------
function! s:python_system(cmd, version)
	if has('nvim')
		let hr = system(a:cmd)
	elseif has('win32') || has('win64') || has('win95') || has('win16')
		if a:version < 0 || (has('python3') == 0 && has('python2') == 0)
			let hr = system(a:cmd)
			let s:shell_error = v:shell_error
			return hr
		elseif a:version == 3
			let pyx = 'py3 '
			let python_eval = 'py3eval'
		elseif a:version == 2
			let pyx = 'py2 '
			let python_eval = 'pyeval'
		else
			let pyx = 'pyx '
			let python_eval = 'pyxeval'
		endif
		exec pyx . 'import subprocess, vim'
		exec pyx . '__argv = {"args":vim.eval("a:cmd"), "shell":True}'
		exec pyx . '__argv["stdout"] = subprocess.PIPE'
		exec pyx . '__argv["stderr"] = subprocess.STDOUT'
		exec pyx . '__pp = subprocess.Popen(**__argv)'
		exec pyx . '__return_text = __pp.stdout.read()'
		exec pyx . '__pp.stdout.close()'
		exec pyx . '__return_code = __pp.wait()'
		exec 'let l:hr = '. python_eval .'("__return_text")'
		exec 'let l:pc = '. python_eval .'("__return_code")'
		let s:shell_error = l:pc
		return l:hr
	else
		let hr = system(a:cmd)
	endif
	let s:shell_error = v:shell_error
	return hr
endfunc


"----------------------------------------------------------------------
" call system 
"----------------------------------------------------------------------
function! asclib#core#system(cmd)
	let hr = s:python_system(a:cmd, get(g:, 'asclib#core#python', 0))
	let g:asclib#core#shell_error = s:shell_error
	return hr
endfunc


"----------------------------------------------------------------------
" display a error msg
"----------------------------------------------------------------------
function! asclib#core#errmsg(what)
	redraw
	echohl ErrorMsg
	echom 'ERROR: ' .. a:what
	echohl None
endfunc


"----------------------------------------------------------------------
" run wsl command
"----------------------------------------------------------------------
function! s:system_wsl(cmd)
	if s:windows == 0
		call asclib#core#errmsg("for windows only")
		return ''
	endif
	let root = ($SystemRoot == '')? 'C:/Windows' : $SystemRoot
	let t1 = root . '/system32/wsl.exe'
	let t2 = root . '/sysnative/wsl.exe'
	let tt = executable(t1)? t1 : (executable(t2)? t2 : '')
	if tt == ''
		call asclib#core#errmsg("not find wsl in your system")
		return ''
	endif
	let cmd = shellescape(substitute(tt, '\\', '\/', 'g'))
	let dist = get(g:, 'asclib#core#wsl_dist', '')
	let cmd = (dist == '')? cmd : (cmd .. ' -d ' .. shellescape(dist))
	return asclib#core#system(cmd .. ' ' .. a:cmd)
endfunc


"----------------------------------------------------------------------
" run msys cmd
"----------------------------------------------------------------------
function! s:system_msys(cmd)
	if s:windows == 0
		call asclib#core#errmsg("for windows only")
		return ''
	endif
	let msys = get(g:, 'asclib#core#msys_home', '')
	if msys == ''
		call asclib#core#errmsg("g:asclib#core#msys_home is empty")
		return ''
	endif
	let msys = tr(msys, "\\", '/')
	if !isdirectory(msys)
		call asclib#core#errmsg("msys does not exist in " .. msys)
		return ''
	endif
	let last = strpart(msys, strlen(msys) - 1, 1)
	let name = (last == '/' || last == "\\")? msys : (msys .. '/')
	let name = name .. 'usr/bin/bash.exe'
	if !executable(name)
		call asclib#core#errmsg("invalid msys path " .. msys)
		return ''
	endif
	let cmd = shellescape(name) .. ' --login -c ' .. shellescape(a:cmd)
	return asclib#core#system(cmd)
endfunc


"----------------------------------------------------------------------
" call system() in linux/unix, or use wsl/msys for windows
"----------------------------------------------------------------------
function! asclib#core#unix_system(cmd)
	if s:windows == 0
		return system(a:cmd)
	endif
	let msys = get(g:, 'asclib#core#msys_home', '')
	if msys == ''
		return s:system_wsl(a:cmd)
	else
		return s:system_msys(a:cmd)
	endif
endfunc



