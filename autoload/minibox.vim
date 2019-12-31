"======================================================================
"
" minibox.vim - 
"
" Created by skywind on 2020/01/01
" Last Modified: 2020/01/01 03:44:53
"
"======================================================================

function! s:python_system(cmd, version)
	if has('win32') || has('win64') || has('win95') || has('win16')
		if a:version < 0
			return system(a:cmd)
		elseif has('python3') == 0 && has('python') == 0
			return system(a:cmd)
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
		exec pyx . '__pp.wait()'
		exec 'let l:hr = '. python_eval .'("__return_text")'
		return l:hr
	else
		return system(a:cmd)
	endif
endfunc

function! PythonSystem(cmd)
	return s:python_system(a:cmd, 3)
endfunc

