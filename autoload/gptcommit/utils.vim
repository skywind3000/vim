"======================================================================
"
" utils.vim - 
"
" Created by skywind on 2024/02/11
" Last Modified: 2024/02/11 20:47:24
"
"======================================================================

let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')
let s:pathsep = (s:windows)? ';' : ':'


"----------------------------------------------------------------------
" Change Directory
"----------------------------------------------------------------------
function! gptcommit#utils#chdir(path)
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	silent execute cmd . ' '. fnameescape(a:path)
endfunc


"----------------------------------------------------------------------
" python simulate system() on window to prevent temporary window
"----------------------------------------------------------------------
function! s:python_system(cmd, version, ...)
	let has_input = (a:0 > 0)? ((type(a:1) == type(''))? 1 : 0) : 0
	let sinput = (has_input)? (a:1) : ''
	if has('nvim')
		let hr = (!has_input)? system(a:cmd) : system(a:cmd, sinput)
	elseif has('win32') || has('win64') || has('win95') || has('win16')
		if a:version < 0 || (has('python3') == 0 && has('python2') == 0)
			let hr = (!has_input)? system(a:cmd) : system(a:cmd, sinput)
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
		if has_input
			exec pyx . '__argv["stdin"] = subprocess.PIPE'
		endif
		exec pyx . '__pp = subprocess.Popen(**__argv)'
		if has_input
			exec pyx . '__si = vim.eval("sinput")'
			exec pyx . '__pp.stdin.write(__si.encode("latin1"))'
			exec pyx . '__pp.stdin.close()'
		endif
		exec pyx . '__return_text = __pp.stdout.read()'
		exec pyx . '__pp.stdout.close()'
		exec pyx . '__return_code = __pp.wait()'
		exec 'let l:hr = '. python_eval .'("__return_text")'
		exec 'let l:pc = '. python_eval .'("__return_code")'
		let s:shell_error = l:pc
		return l:hr
	else
		let hr = (!has_input)? system(a:cmd) : system(a:cmd, sinput)
	endif
	let s:shell_error = v:shell_error
	return hr
endfunc


"----------------------------------------------------------------------
" call system: system(cmd [, cwd [, encoding [, input]]])
"----------------------------------------------------------------------
function! gptcommit#utils#system(cmd, ...)
	let cwd = ((a:0) > 0)? (a:1) : ''
	if cwd != ''
		let previous = getcwd()
		noautocmd call gptcommit#utils#chdir(cwd)
	endif
	if a:0 >= 3
		if type(a:3) == type('')
			let sinput = a:3
		else
			let sinput = (type(a:3) == type([]))? join(a:3, "\n") : {}
		endif
	else
		let sinput = {}
	endif
	let hr = s:python_system(a:cmd, get(g:, 'gptcommit#utils#python', 0), sinput)
	if cwd != ''
		noautocmd call gptcommit#utils#chdir(previous)
	endif
	let g:gptcommit#utils#shell_error = s:shell_error
	if (a:0) > 1 && has('iconv')
		let encoding = a:2
		if encoding != '' && encoding != &encoding
			try
				let hr = iconv(hr, a:2, &encoding)
			catch
			endtry
		endif
	endif
	return hr
endfunc


"----------------------------------------------------------------------
" display a error msg
"----------------------------------------------------------------------
function! gptcommit#utils#errmsg(what) abort
	redraw
	echohl ErrorMsg
	echom 'ERROR: ' . a:what
	echohl None
endfunc


"----------------------------------------------------------------------
" find python
"----------------------------------------------------------------------
function! gptcommit#utils#find_python() abort
	if exists('g:git_commit_python')
		if executable(g:git_commit_python)
			return g:git_commit_python
		endif
	endif
	if exists('g:python3_host_prog')
		if executable(g:python3_host_prog)
			return g:python3_host_prog
		endif
	endif
	if s:windows
		if executable('python.exe')
			return 'python.exe'
		endif
	else
		for exe in ['python3', 'python']
			if executable(exe)
				return exe
			endif
		endfor
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" find script
"----------------------------------------------------------------------
function! gptcommit#utils#find_script() abort
	let base = fnamemodify(s:scripthome, ':h:h')
	let t1 = printf('%s/%s', s:scripthome, 'gptcommit.py')
	let t2 = printf('%s/bin/%s', base, 'gptcommit.py')
	let t3 = printf('%s/lib/%s', base, 'gptcommit.py')
	for tt in [t1, t2, t3]
		if filereadable(tt)
			let tt = tr(tt, "\\", '/')
			if s:windows
				let tt = tr(tt, '/', '\')
			endif
			return tt
		endif
	endfor
	return ''
endfunc



"----------------------------------------------------------------------
" run gptcommit.py 
"----------------------------------------------------------------------
function! gptcommit#utils#request(args) abort
	let python = gptcommit#utils#find_python()
	if python == ''
		call gptcommit#utils#errmsg('python3 executable file missing')
		return ''
	endif
	let script = gptcommit#utils#find_script()
	if script == ''
		call gptcommit#utils#errmsg('gptcommit.py script missing')
		return ''
	endif
	let cmd = printf('%s %s', shellescape(python), shellescape(script))
	let cmd = cmd . ' --utf8'
	if s:windows
		let cmd = 'call ' . cmd
	endif
	for n in a:args
		let cmd = cmd . ' ' . shellescape(n)
	endfor
	let text = system(cmd)
	if &encoding != 'utf-8'
		if has('iconv') && &encoding != ''
			let text = iconv(text, 'utf-8', &encoding)
		endif
	endif
	let textlist = split(text, "\n")
	return join(textlist, "\n")
endfunc


"----------------------------------------------------------------------
" guess repo
"----------------------------------------------------------------------
function! gptcommit#utils#current_path()
	if &bt != ''
		if &ft == 'fugitive'
			let fn = expand('%:p')
			if fn =~ '\v^fugitive\:[\\\/][\\\/][\\\/]'
				let path = strpart(fn, s:windows? 12 : 11)
				let pos = stridx(path, '.git')
				if pos >= 0
					let path = strpart(path, 0, pos)
				endif
				return fnamemodify(path, ':h')
			endif
		endif
		return getcwd()
	elseif expand('%:p') == ''
		return getcwd()
	endif
	if &ft == 'gitcommit'
		if expand('%:p') =~ '\v[\\\/]\.git[\\\/]COMMIT_EDITMSG$'
			return expand('%:p:h:h')
		endif
	endif
	return expand('%:p:h')
endfunc


"----------------------------------------------------------------------
" check if a buffer is writable
"----------------------------------------------------------------------
function! gptcommit#utils#buffer_writable() abort
	if &bt != ''
		return 0
	elseif &modifiable == 0
		return 0
	elseif &readonly
		return 0
	endif
	return 1
endfunc



"----------------------------------------------------------------------
" find repo root, returns empty string if not in a repository
"----------------------------------------------------------------------
function! gptcommit#utils#repo_root(path)
	let name = fnamemodify((a:path == '')? bufname('%') : (a:path), ':p')
	let find = finddir('.git', name . '/;')
	if find == ''
		return ''
	endif
	let find = fnamemodify(find, ':p:h:h')
	return find
endfunc



