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
" Global
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let g:asclib#core#windows = s:windows
let g:asclib#core#has_nvim = has('nvim')


"----------------------------------------------------------------------
" Get Instance
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
" Change Directory
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
" Safe Input
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
" call system: system(cmd [, cwd [, encoding]])
"----------------------------------------------------------------------
function! asclib#core#system(cmd, ...)
	let cwd = ((a:0) > 0)? (a:1) : ''
	if cwd != ''
		let previous = getcwd()
		call asclib#core#chdir(cwd)
	endif
	let hr = s:python_system(a:cmd, get(g:, 'asclib#core#python', 0))
	if cwd != ''
		call asclib#core#chdir(previous)
	endif
	let g:asclib#core#shell_error = s:shell_error
	if (a:0) > 1 && has('iconv')
		let encoding = a:2
		if encoding != '' && encoding != &encoding
			try
				let hr = iconv(hr, a:2, &encoding)
			catch /.*/
			endtry
		endif
	endif
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
function! asclib#core#unix_system(cmd, ...)
	let cwd = ((a:0) > 0)? (a:1) : ''
	if cwd != ''
		let previous = getcwd()
		call asclib#core#chdir(cwd)
	endif
	if s:windows == 0
		let hr = system(a:cmd)
	else
		let msys = get(g:, 'asclib#core#msys_home', '')
		if msys == ''
			let hr = s:system_wsl(a:cmd)
		else
			let hr = s:system_msys(a:cmd)
		endif
	endif
	if cwd != ''
		call asclib#core#chdir(previous)
	endif
	if (a:0) > 1 && has('iconv')
		let hr = iconv(hr, a:2, &encoding)
	endif
	return hr
endfunc


"----------------------------------------------------------------------
" write script to a file and return filename
"----------------------------------------------------------------------
function! asclib#core#script_write(name, command, pause)
	let tmpname = fnamemodify(tempname(), ':h') . '\' . (a:name) . '.cmd'
	let command = a:command
	if s:windows != 0
		let lines = ["@echo off\r"]
		let $VIM_COMMAND = a:command
		let $VIM_PAUSE = (a:pause)? 'pause' : ''
		if a:pause < 0
			let $VIM_PAUSE = 'timeout ' . (-(a:pause)) . ' > nul'
		endif
		let lines += ["call %VIM_COMMAND% \r"]
		let lines += ["set VIM_EXITCODE=%ERRORLEVEL%\r"]
		let lines += ["call %VIM_PAUSE% \r"]
		let lines += ["exit %VIM_EXITCODE%\r"]
	else
		let shell = split(&shell, ' ')[0]
		let shell = (shell == 'fish')? 'bash' : shell
		let lines = ['#! ' . shell]
		let lines += [command]
		if a:pause > 0
			if executable('bash')
				let pause = 'read -n1 -rsp "press any key to continue ..."'
				let lines += ['bash -c ''' . pause . '''']
			else
				let lines += ['echo "press enter to continue ..."']
				let lines += ['sh -c "read _tmp_"']
			endif
		elseif a:pause < 0
			let lines += ['sleep ' . (-(a:pause))]
		endif
		let tmpname = fnamemodify(tempname(), ':h') . '/' . (a:name) . '.sh'
	endif
	if v:version >= 700
		call writefile(lines, tmpname)
	else
		exe 'redir ! > '.fnameescape(tmpname)
		for line in lines
			silent echo line
		endfor
		redir END
	endif
	if s:windows == 0
		if exists('*setfperm')
			silent! call setfperm(tmpname, 'rwxrwxrws')
		endif
	endif
	return tmpname
endfunc


"----------------------------------------------------------------------
" prototype: 
"     text_process(command, stdin [, cwd [, encoding]])
"
" run text filter: stdin is a string list which will pass to the 
" stdin of command. returns the command output.
"----------------------------------------------------------------------
function! asclib#core#text_process(command, stdin, ...) abort
	let tmpname = tempname()
	let cwd = (a:0 > 0)? (a:1) : ''
	let encoding = (a:0 > 1)? (a:2) : ''
	let encoding = (encoding == &encoding)? '' : encoding
	let input = []
	if type(a:stdin) == 1
		let input = split(a:stdin, "\n")
	else
		let input = deepcopy(a:stdin)
	endif
	if s:windows
		" let input = map(input, 'v:val . "\r"')
	endif
	call writefile(input, tmpname)
	if filereadable(tmpname) == 0
		return ''
	endif
	let outname = tempname()
	let script = asclib#core#script_write('vim_pipe', a:command, 0)
	let cmd = script . ' < ' . shellescape(tmpname) 
	let cmd = cmd . ' > ' . shellescape(outname) . ' 2>&1'
	let hr = asclib#core#system(cmd, cwd, encoding)
	let hr = readfile(outname)
	silent! call delete(tmpname)
	silent! call delete(outname)
	let textlist = []
	for text in hr
		if encoding != ''
			try
				let text = iconv(text, encoding, &encoding)
			catch /.*/
			endtry
		endif
		let text = substitute(text, '\r$', '', 'g')
		let textlist += [text]
	endfor
	return textlist
endfunc


"----------------------------------------------------------------------
" replace the text from range
"----------------------------------------------------------------------
function! asclib#core#text_replace(bid, lnum, count, program) abort
	if a:count <= 0
		return 0
	endif
	let text = getbufline(a:bid, a:lnum, a:lnum + a:count - 1)
	if type(a:program) == v:t_string
		if a:program =~ '^\s*:'
			let funname = matchstr(a:program, '^\s*:\zs.*$')
			let hr = call(funname, [text])
		else
			let hr = asclib#core#text_process(a:program, text)
		endif
	elseif type(a:program) == v:t_func
		let hr = call(a:program, [text])
	endif
	if len(text) < len(hr)
		call appendbufline(a:bid, a:lnum, repeat([''], len(hr) - len(text)))
	elseif len(text) > len(hr)
		call deletebufline(a:bid, a:lnum, a:lnum + len(text) - len(hr) - 1)
	endif
	call setbufline(a:bid, a:lnum, hr)
endfunc


"----------------------------------------------------------------------
" extract opts+command
"----------------------------------------------------------------------
function! asclib#core#extract(command)
	let cmd = substitute(a:command, '^\s*\(.\{-}\)[\s\r\n]*$', '\1', '')
	let opts = {}
	while cmd =~# '^-\%(\w\+\)\%([= ]\|$\)'
		let opt = matchstr(cmd, '^-\zs\w\+')
		if cmd =~ '^-\w\+='
			let val = matchstr(cmd, '^-\w\+=\zs\%(\\.\|\S\)*')
		else
			let val = ''
		endif
		let opts[opt] = substitute(val, '\\\(\s\)', '\1', 'g')
		let cmd = substitute(cmd, '^-\w\+\%(=\%(\\.\|\S\)*\)\=\s*', '', '')
	endwhile
	let cmd = substitute(cmd, '^\s*\(.\{-}\)\s*$', '\1', '')
	let cmd = substitute(cmd, '^@\s*', '', '')
	return [cmd, opts]
endfunc


"----------------------------------------------------------------------
" switch buffer
"----------------------------------------------------------------------
function! asclib#core#switch(filename, opts)
	let switch = get(g:, 'asclib#core#switch_mode', &switchbuf)
	let switch = get(a:opts, 'switch', switch)
	let method = split(switch, ',')
	let goto = get(a:opts, 'goto', -1)
	let ft = get(a:opts, 'ft', '')
	let cmds = get(a:opts, 'command', [])
	if type(a:filename) == type('')
		let filename = expand(a:filename)
		if filereadable(filename) == 0
			if get(a:opts, 'exist', 0) != 0
				echohl ErrorMsg
				echom "E484: Can't open file " . (a:filename)
				echohl None
				return 0
			endif
		endif
		let bid = bufnr(filename)
	else
		let bid = a:filename
		if bid < 0
			return 0
		endif
	endif
	if index(method, 'useopen') >= 0
		for wid in range(winnr('$'))
			let b = winbufnr(wid + 1)
			if b == bid
				silent exec ''. (wid + 1) . 'wincmd w'
				if goto > 0
					silent exec ':' . goto
				endif
				for cmd in cmds
					exec cmd
				endfor
				return 1
			endif
		endfor
	endif
	if index(method, 'usetab') >= 0
		for tid in range(tabpagenr('$'))
			let buflist = tabpagebuflist(tid + 1)
			for wid in range(len(buflist))
				if bid == buflist[wid]
					silent exec 'tabn ' . (tid + 1)
					silent exec '' . (wid + 1) . 'wincmd w'
					if goto > 0
						silent exec ':' . goto
					endif
					for cmd in cmds
						exec cmd
					endfor
					return 1
				endif
			endfor
		endfor
	endif
	if index(method, 'newtab') >= 0
		silent exec 'tab split'
	elseif index(method, 'uselast') >= 0
		silent exec 'wincmd p'
	elseif index(method, 'edit') >= 0
		silent exec ''
	elseif index(method, 'drop') >= 0
	else
		if &buftype != ''
			silent exec 'wincmd p'
		endif
		for i in range(winnr('$'))
			if &buftype == ''
				break
			endif
			silent exec 'wincmd w'
		endfor
		let mods = get(a:opts, 'mods', '')
		if index(method, 'auto') >= 0
			if winwidth(0) >= 160
				exec mods . ' vsplit'
			else
				exec mods . ' split'
			endif
		elseif index(method, 'split') >= 0
			exec mods . ' split'
		elseif index(method, 'vsplit') >= 0
			exec mods . ' vsplit'
		endif
	endif
	try
		let force = ((get(a:opts, 'force', 0) != 0)? '!' : '')
		if bid >= 0
			exec 'b' . force . ' ' . bid
		else
			exec 'edit' . force . ' ' . fnameescape(expand(a:filename))
		endif
	catch /^Vim\%((\a\+)\)\=:E37:/ 
		echohl ErrorMsg
		echo 'E37: No write since last change (set force=1 to override)'
		echohl None
		return 0
	endtry
	if goto > 0
		exec ':' . goto
	endif
	if ft != ''
		exec 'setlocal ft=' . fnameescape(ft)
	endif
	for cmd in cmds
		exec cmd
	endfor
	return 1
endfunc



