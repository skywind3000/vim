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
	if has('python')
		let s:py_cmd = 'py'
		let s:py_eval = 'pyeval'
		let s:py_version = 2
	elseif has('python3')
		let s:py_cmd = 'py3'
		let s:py_eval = 'py3eval'
		let s:py_version = 3
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


"----------------------------------------------------------------------
" interfaces 
"----------------------------------------------------------------------
function! asclib#python#exec(script) abort
	if s:py_version == 0
		call asclib#common#errmsg('vim does not support python')
		return
	endif
	exec s:py_cmd a:script
endfunc

function! asclib#python#eval(script) abort
	if s:py_version == 0
		call asclib#common#errmsg('vim does not support python')
		return 0
	elseif s:py_version == 2
		return pyeval(a:script)
	elseif s:py_version == 3
		return py3eval(a:script)
	endif
endfunc

