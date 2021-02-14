"======================================================================
"
" python.vim - 
"
" Created by skywind on 2018/05/06
" Last Modified: 2018/05/06 14:56:24
"
"======================================================================

if !exists('g:asclib#python#version')
	let g:asclib#python#version = 0
endif


"----------------------------------------------------------------------
" version detection
"----------------------------------------------------------------------
let s:py_cmd = ''
let s:py_eval = ''
let s:py_version = 0

if g:asclib#python#version == 0
	if has('python3')
		let s:py_cmd = 'py3'
		let s:py_eval = 'py3eval'
		let s:py_version = 3
	elseif has('python')
		let s:py_cmd = 'py'
		let s:py_eval = 'pyeval'
		let s:py_version = 2
	else
		call asclib#common#errmsg('vim does not support +python/+python3 feature')
	endif
elseif g:asclib#python#version == 2
	if has('python')
		let s:py_cmd = 'py'
		let s:py_eval = 'pyeval'
		let s:py_version = 2
	else
		call asclib#common#errmsg('vim does not support +python feature')
	endif
else
	if has('python3')
		let s:py_cmd = 'py3'
		let s:py_eval = 'py3eval'
		let s:py_version = 3
	else
		call asclib#common#errmsg('vim does not support +python3 feature')
	endif
endif


"----------------------------------------------------------------------
" variables
"----------------------------------------------------------------------
let g:asclib#python#py_ver = s:py_version
let g:asclib#python#py_cmd = s:py_cmd
let g:asclib#python#py_eval = s:py_eval
let g:asclib#python#shell_error = 0

let g:asclib#python#locate = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:asclib#python#rtp = fnamemodify(g:asclib#python#locate, ':h:h')


"----------------------------------------------------------------------
" core python 
"----------------------------------------------------------------------
function! asclib#python#exec(script) abort
	if s:py_version == 0
		call asclib#common#errmsg('vim does not support python')
	elseif type(a:script) == 1
		exec s:py_cmd a:script
	elseif type(a:script) == 3
		let code = join(a:script, "\n")
		exec s:py_cmd code
	endif
endfunc

function! asclib#python#eval(script) abort
	if s:py_version == 0
		call asclib#common#errmsg('vim does not support python')
		return -1
	else
		if type(a:script) == 1
			let code = a:script
		elseif type(a:script) == 3
			let code = join(a:script, "\n")
		else
			let code = "0"
		endif
		if s:py_version == 2
			return pyeval(code)
		elseif s:py_version == 3
			return py3eval(code)
		endif
	endif
endfunc

function! asclib#python#system(command)
	if g:asclib#common#windows == 0 || s:py_version == 0
		let text = system(a:command)
		let g:asclib#python#shell_error = v:shell_error
		return text
	else
		exec s:py_cmd 'import subprocess, vim'
		exec s:py_cmd '__argv = {"args": vim.eval("a:command")}'
		exec s:py_cmd '__argv["shell"] = True'
		exec s:py_cmd '__argv["stdout"] = subprocess.PIPE'
		exec s:py_cmd '__argv["stderr"] = subprocess.STDOUT'
		exec s:py_cmd '__pp = subprocess.Popen(**__argv)'
		exec s:py_cmd '__return_text = __pp.stdout.read()'
		exec s:py_cmd '__return_code = __pp.wait()'
		let g:asclib#python#shell_error = asclib#python#eval('__return_code')
		return asclib#python#eval('__return_text')
	endif
endfunc


"----------------------------------------------------------------------
" module manipulate
"----------------------------------------------------------------------
function! asclib#python#path_add(path)
	if s:py_version == 0
		call asclib#common#errmsg('vim does not support python')
		return 0
	endif
	exec s:py_cmd "import sys, os, vim"
	exec s:py_cmd '__pp = os.path.abspath(vim.eval("a:path"))'
	exec s:py_cmd 'if __pp not in sys.path: sys.path.append(__pp)'
	return 1
endfunc

function! asclib#python#reload(module_name)
	if s:py_version == 0
		call asclib#common#errmsg('vim does not support python')
		return 0
	endif
	if s:py_version == 3
		exec s:py_cmd 'import importlib as __imp'
	else
		exec s:py_cmd 'import imp as __imp'
	endif
	exec s:py_cmd 'import vim'
	exec s:py_cmd 'import ' . a:module_name . ' as __mm'
	exec s:py_cmd '__imp.reload(__mm)'
	return 1
endfunc


