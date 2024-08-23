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
" script home
"----------------------------------------------------------------------
let s:script_home = fnamemodify(expand('<sfile>:p'), ':h')


"----------------------------------------------------------------------
" version detection
"----------------------------------------------------------------------
let s:py_cmd = ''
let s:py_eval = ''
let s:py_file = ''
let s:py_version = 0
let s:py_ensure = 0
let s:py_inited = 0
let s:py_health = ''

if g:asclib#python#version == 0
	if has('python3')
		let s:py_cmd = 'py3'
		let s:py_eval = 'py3eval'
		let s:py_file = 'py3file'
		let s:py_version = 3
	elseif has('python')
		let s:py_cmd = 'py'
		let s:py_eval = 'pyeval'
		let s:py_file = 'pyfile'
		let s:py_version = 2
	else
		let s:py_health = 'require +python/+python3 feature'
	endif
elseif g:asclib#python#version == 2
	if has('python')
		let s:py_cmd = 'py'
		let s:py_eval = 'pyeval'
		let s:py_file = 'pyfile'
		let s:py_version = 2
	else
		let s:py_health = 'require +python feature'
	endif
else
	if has('python3')
		let s:py_cmd = 'py3'
		let s:py_eval = 'py3eval'
		let s:py_file = 'py3file'
		let s:py_version = 3
	else
		let s:py_health = 'require +python3 feature'
	endif
endif


"----------------------------------------------------------------------
" variables
"----------------------------------------------------------------------
let g:asclib#python#py_ver = s:py_version
let g:asclib#python#py_cmd = s:py_cmd
let g:asclib#python#py_eval = s:py_eval
let g:asclib#python#py_file = s:py_file
let g:asclib#python#shell_error = 0

let g:asclib#python#locate = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:asclib#python#rtp = fnamemodify(g:asclib#python#locate, ':h:h')



"----------------------------------------------------------------------
" returns 0 for no python, 2 for +python2, 3 for +python3
"----------------------------------------------------------------------
function! asclib#python#has_python()
	return s:py_version
endfunc


"----------------------------------------------------------------------
" health check
"----------------------------------------------------------------------
function! asclib#python#checkhealth()
	if s:py_version == 0
		call asclib#core#errmsg(s:py_health)
	else
		echo "Python" . s:py_version . ' is enabled.'
	endif
	return s:py_health
endfunc


"----------------------------------------------------------------------
" core python 
"----------------------------------------------------------------------
function! asclib#python#exec(script) abort
	if s:py_version == 0
		call asclib#python#checkhealth()
	elseif type(a:script) == 1
		exec s:py_cmd a:script
	elseif type(a:script) == 3
		let code = join(a:script, "\n")
		exec s:py_cmd code
	endif
endfunc


"----------------------------------------------------------------------
" eval script
"----------------------------------------------------------------------
function! asclib#python#eval(script) abort
	if s:py_version == 0
		call asclib#python#checkhealth()
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


"----------------------------------------------------------------------
" python file
"----------------------------------------------------------------------
function! asclib#python#file(filename) abort
	if s:py_version == 0
		call asclib#python#checkhealth()
	else
		exec s:py_file . ' ' . fnameescape(a:filename)
	endif
endfunc


"----------------------------------------------------------------------
" python call
"----------------------------------------------------------------------
function! asclib#python#call(funcname, args) abort
	if s:py_version == 0
		call asclib#python#checkhealth()
		return
	else
		if s:py_ensure == 0
			exec s:py_cmd 'import vim'
			let s:py_ensure = 1
		endif
		if s:py_version == 2
			py __py_args = vim.eval('a:args')
			return pyeval(a:funcname . '(*__py_args)')
		else
			py3 __py_args = vim.eval('a:args')
			return py3eval(a:funcname . '(*__py_args)')
		endif
	endif
endfunc


"----------------------------------------------------------------------
" python system
"----------------------------------------------------------------------
function! asclib#python#system(cmd, ...)
	let has_input = 0
	if a:0 > 0
		if type(a:1) == type('')
			let sinput = a:1
			let has_input = 1
		elseif type(a:1) == type([])
			let sinput = join(a:1, "\n")
			let has_input = 1
		endif
	endif
	if g:asclib#common#windows == 0 || s:py_version == 0
		let text = (!has_input)? system(a:cmd) : system(a:cmd, sinput)
		let g:asclib#python#shell_error = v:shell_error
		return text
	endif
	exec s:py_cmd 'import subprocess, vim'
	exec s:py_cmd '__argv = {"args": vim.eval("a:cmd")}'
	exec s:py_cmd '__argv["shell"] = True'
	exec s:py_cmd '__argv["stdout"] = subprocess.PIPE'
	exec s:py_cmd '__argv["stderr"] = subprocess.STDOUT'
	if has_input
		exec s:py_cmd '__argv["stdin"] = subprocess.PIPE'
	endif
	exec s:py_cmd '__pp = subprocess.Popen(**__argv)'
	if has_input
		exec s:py_cmd . '__si = vim.eval("sinput")'
		exec s:py_cmd . '__pp.stdin.write(__si.encode("latin1"))'
		exec s:py_cmd . '__pp.stdin.close()'
	endif
	exec s:py_cmd '__return_text = __pp.stdout.read()'
	exec s:py_cmd '__return_code = __pp.wait()'
	let g:asclib#python#shell_error = asclib#python#eval('__return_code')
	return asclib#python#eval('__return_text')
endfunc


"----------------------------------------------------------------------
" module manipulate
"----------------------------------------------------------------------
function! asclib#python#path_add(path)
	if s:py_version == 0
		call asclib#python#checkhealth()
		return 0
	endif
	exec s:py_cmd "import sys, os, vim"
	exec s:py_cmd '__pp = os.path.abspath(vim.eval("a:path"))'
	exec s:py_cmd 'if __pp not in sys.path: sys.path.append(__pp)'
	return 1
endfunc


"----------------------------------------------------------------------
" addsitedir
"----------------------------------------------------------------------
function! asclib#python#site_add(path)
	if s:py_version == 0
		call asclib#python#checkhealth()
		return 0
	endif
	exec s:py_cmd "import site, os, vim"
	exec s:py_cmd '__pp = os.path.abspath(vim.eval("a:path"))'
	exec s:py_cmd 'site.addsitedir(__pp)'
	return 1
endfunc


"----------------------------------------------------------------------
" reload 
"----------------------------------------------------------------------
function! asclib#python#reload(module_name)
	if s:py_version == 0
		call asclib#python#checkhealth()
		return 0
	endif
	if s:py_inited == 0
		call asclib#python#init()
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


"----------------------------------------------------------------------
" import
"----------------------------------------------------------------------
function! asclib#python#import(module_name)
	if s:py_version == 0
		call asclib#python#checkhealth()
		return 0
	endif
	if s:py_inited == 0
		call asclib#python#init()
	endif
	exec s:py_cmd 'import ' . a:module_name
	return 1
endfunc


"----------------------------------------------------------------------
" initialize asclib.py
"----------------------------------------------------------------------
function! asclib#python#init()
	if s:py_version == 0
		call asclib#python#checkhealth()
		return 0
	elseif s:py_inited != 0
		return 1
	endif
	exec s:py_cmd 'import vim, sys, os, site'
	call asclib#python#site_add(s:script_home)
	exec s:py_cmd '__path = vim.eval("s:script_home") + "/../python"'
	exec s:py_cmd '__path = os.path.normpath(__path)'
	exec s:py_cmd 'site.addsitedir(__path)'
	exec s:py_cmd '__path = vim.eval("s:script_home") + "/../../lib"'
	exec s:py_cmd '__path = os.path.normpath(__path)'
	exec s:py_cmd 'site.addsitedir(__path)'
	exec s:py_cmd '__path = vim.eval("s:script_home") + "/../../python"'
	exec s:py_cmd '__path = os.path.normpath(__path)'
	exec s:py_cmd 'site.addsitedir(__path)'
	exec s:py_cmd '__path = vim.eval("s:script_home") + "/../../site"'
	exec s:py_cmd '__path = os.path.normpath(__path + "/site-packages")'
	exec s:py_cmd 'site.addsitedir(__path)'
	let script = []
	let script += ['__pset = {}']
	let script += ['__plst = []']
	let script += ['for __path in sys.path:']
	let script += ['    if not os.path.exists(__path):']
	let script += ['        if __path != "_vim_path_":']
	let script += ['            continue']
	let script += ['    if __path not in __pset:']
	let script += ['        __pset[__path] = 1']
	let script += ['        __plst.append(__path)']
	let script += ['sys.path = __plst']
	exec s:py_cmd join(script, "\n")
	let fn = s:script_home . '/_asclib.py'
	if filereadable(fn)
		exec s:py_cmd 'import _asclib'
	endif
	let s:py_ensure = 1
	let s:py_inited = 1
	return 1
endfunc


"----------------------------------------------------------------------
" pprint
"----------------------------------------------------------------------
function! asclib#python#pprint(obj)
	call asclib#python#init()
	exec s:py_cmd 'import pprint'
	exec s:py_cmd '__obj = vim.eval("a:obj")'
	exec s:py_cmd 'pprint.pprint(__obj)'
	" exec s:py_cmd 'print(type(__obj))'
endfunc


"----------------------------------------------------------------------
" returns import base and name
"----------------------------------------------------------------------
function! asclib#python#get_imp_info(pyfile)
	let path = a:pyfile
	if path == '' || path == '%'
		let path = expand('%')
	endif
	let path = asclib#path#abspath(path)
	let home = asclib#path#dirname(path)
	let name = asclib#path#basename(path)
	let part = asclib#path#splitext(name)[0]
	while 1
		let t = asclib#path#join(home, '__init__.py')
		if !asclib#path#exists(t)
			break
		endif
		let p = fnamemodify(home, ':t')
		let part = p . '.' . part
		let t = asclib#path#normalize(asclib#path#join(home, '..'))
		if asclib#path#equal(t, home)
			break
		endif
		let home = t
	endwhile
	return [home, part]
endfunc


"----------------------------------------------------------------------
" get import base directory 
"----------------------------------------------------------------------
function! asclib#python#get_imp_base(pyfile)
	let res = asclib#python#get_imp_info(a:pyfile)
	return res[0]
endfunc


"----------------------------------------------------------------------
" get import name
"----------------------------------------------------------------------
function! asclib#python#get_imp_name(pyfile)
	let res = asclib#python#get_imp_info(a:pyfile)
	return res[1]
endfunc


"----------------------------------------------------------------------
" reload a python script
"----------------------------------------------------------------------
function! asclib#python#refresh(pyfile)
	let iname = asclib#python#get_imp_name(a:pyfile)
	call asclib#python#reload(iname)
endfunc


"----------------------------------------------------------------------
" test time
"----------------------------------------------------------------------
function! asclib#python#timing() abort
	let ts = reltime()
	call asclib#python#import('site')
	let tt = reltimestr(reltime(ts))
	return tt
endfunc



