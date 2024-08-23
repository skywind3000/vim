" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :
"======================================================================
"
" core.vim - 
"
" Created by skywind on 2020/02/06
" Last Modified: 2024/03/20 22:47
"
"======================================================================


"----------------------------------------------------------------------
" Global Variable
"----------------------------------------------------------------------
let g:asclib = get(g:, 'asclib', {})


"----------------------------------------------------------------------
" Compatibility Check
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let s:has_windows = s:windows
let s:has_nvim = has('nvim')
let s:has_vim9 = v:version >= 900
let s:has_popup = exists('*popup_create') && v:version >= 800
let s:has_floating = has('nvim-0.4')
let s:has_vim9script = (v:version >= 900) && has('vim9script')
let s:has_winexe = exists('*win_execute')
let s:has_winapi = exists('*nvim_set_current_win')
let s:has_winid = exists('*win_gotoid')
let s:has_execute = exists('*execute')


"----------------------------------------------------------------------
" core object: 'b' for buffer, 't' for tab, 'g' for global
"----------------------------------------------------------------------
function! asclib#core#object(scope)
	if a:scope == 'g'
		if !exists('g:__asclib__')
			let g:__asclib__ = {}
		endif
		return g:__asclib__
	elseif a:scope == 't'
		if !exists('t:__asclib__')
			let t:__asclib__ = {}
		endif
		return t:__asclib__
	elseif a:scope == 'b'
		if !exists('b:__asclib__')
			let b:__asclib__ = {}
		endif
		return b:__asclib__
	elseif a:scope == 'w'
		if !exists('w:__asclib__')
			let w:__asclib__ = {}
		endif
		return w:__asclib__
	endif
	if !exists('s:__asclib__')
		let s:__asclib__ = {}
	endif
	return s:__asclib__
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
" CD command
"----------------------------------------------------------------------
function! asclib#core#getcd()
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	return cmd
endfunc


"----------------------------------------------------------------------
" execute ex command
"----------------------------------------------------------------------
function! asclib#core#execute(cmd, ...)
	if s:has_execute
		if a:0 == 0
			return execute(a:cmd)
		else
			return execute(a:cmd, a:1)
		endif
	else
		if type(a:cmd) == type([])
			let cmd = join(a:cmd, "\n")
		else
			let cmd = a:cmd
		endif
		redir => l:hr
		if a:0 == 0
			exec cmd
		elseif a:1 == 'silent'
			silent exec cmd
		elseif a:1 == 'silent!'
			silent! exec cmd
		else
			exec cmd
		endif
		redir END
		return l:hr
	endif
endfunc


"----------------------------------------------------------------------
" win_execute: execute command in a window
"----------------------------------------------------------------------
function! asclib#core#win_execute(winid, command, ...)
	let silent = (a:0 < 1)? 0 : (a:1)
	let command = ''
	if type(a:command) == v:t_string
		let command = a:command
	elseif type(a:command) == v:t_list
		let command = join(a:command, "\n")
	endif
	if s:has_winexe != 0
		keepalt call win_execute(a:winid, command, silent)
	elseif s:has_winapi
		let current = nvim_get_current_win()
		keepalt call nvim_set_current_win(a:winid)
		if nvim_get_current_win() == a:winid
			if silent == 0
				exec command
			else
				silent exec command
			endif
		endif
		keepalt call nvim_set_current_win(current)
	elseif s:has_winid
		let current = win_getid()
		keepalt call win_gotoid(a:winid)
		if win_getid() == a:winid
			if silent == 0
				exec command
			else
				silent exec command
			endif
		endif
		keepalt call win_gotoid(current)
	endif
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
" Safe confirm
"----------------------------------------------------------------------
function! asclib#core#confirm(msg, choices, default)
	call inputsave()
	try
		let hr = confirm(a:msg, choices, default)
	catch /^Vim:Interrupt$/
		let hr = 0
	endtry
	call inputrestore()
	return hr
endfunc


"----------------------------------------------------------------------
" Safe inputlist
"----------------------------------------------------------------------
function! asclib#core#inputlist(textlist)
	call inputsave()
	try
		let hr = inputlist(a:textlist)
	catch /^Vim:Interrupt$/
		let hr = -1
	endtry
	call inputrestore()
	return hr
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
function! asclib#core#system(cmd, ...)
	let cwd = ((a:0) > 0)? (a:1) : ''
	if cwd != ''
		let previous = getcwd()
		noautocmd call asclib#core#chdir(cwd)
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
	let hr = s:python_system(a:cmd, get(g:, 'asclib#core#python', 0), sinput)
	if cwd != ''
		noautocmd call asclib#core#chdir(previous)
	endif
	let g:asclib#core#shell_error = s:shell_error
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
function! asclib#core#errmsg(what)
	redraw
	echohl ErrorMsg
	echom 'ERROR: ' . a:what
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
	let cmd = (dist == '')? cmd : (cmd . ' -d ' . shellescape(dist))
	return asclib#core#system(cmd . ' ' . a:cmd)
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
		call asclib#core#errmsg("msys does not exist in " . msys)
		return ''
	endif
	let last = strpart(msys, strlen(msys) - 1, 1)
	let name = (last == '/' || last == "\\")? msys : (msys . '/')
	let name = name . 'usr/bin/bash.exe'
	if !executable(name)
		call asclib#core#errmsg("invalid msys path " . msys)
		return ''
	endif
	let cmd = shellescape(name) . ' --login -c ' . shellescape(a:cmd)
	return asclib#core#system(cmd)
endfunc


"----------------------------------------------------------------------
" call system() in linux/unix, or use wsl/msys for windows
"----------------------------------------------------------------------
function! asclib#core#unix_system(cmd, ...)
	let cwd = ((a:0) > 0)? (a:1) : ''
	if cwd != ''
		let previous = getcwd()
		noautocmd call asclib#core#chdir(cwd)
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
		noautocmd call asclib#core#chdir(previous)
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
		silent! call writefile(lines, tmpname)
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
" safe shell escape for neovim
"----------------------------------------------------------------------
function! asclib#core#shellescape(path)
	if s:windows == 0
		return shellescape(a:path)
	endif
	let hr = shellescape(a:path)
	if &ssl != 0
		let parts = split(hr, "'", 1)
		let hr = join(parts, '"')
	endif
	return hr
endfunc


"----------------------------------------------------------------------
" start shell command in background: start(cmd [, cwd])
"----------------------------------------------------------------------
function! asclib#core#start(cmd, ...)
	let cmd = a:cmd
	let cwd = ((a:0) > 0)? (a:1) : ''
	if cwd != ''
		let previous = getcwd()
		noautocmd call asclib#core#chdir(cwd)
	endif
	if s:windows == 0
		call system(a:cmd . ' &')
	else
		let winsafe = get(g:, 'asclib#core#winsafe', 1)
		if winsafe != 0
			let ccc = asclib#core#script_write('asclib1', cmd, 0)
			let cmd = asclib#core#shellescape(ccc)
		endif
		silent exec '!start /b cmd /C ' . cmd
	endif
	if cwd != ''
		noautocmd call asclib#core#chdir(previous)
	endif
	return 0
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
	let script = asclib#core#script_write('vim_pipe', a:command, 0)
	let mode = 0
	if mode == 0
		let cmd = script . ' < ' . shellescape(tmpname)  . ' 2>&1'
		let hr = asclib#core#system(cmd, cwd, encoding)
		let hr = split(hr, "\n")
	else
		let outname = tempname()
		let cmd = script . ' < ' . shellescape(tmpname) 
		let cmd = cmd . ' > ' . shellescape(outname) . ' 2>&1'
		let hr = asclib#core#system(cmd, cwd, encoding)
		let hr = readfile(outname)
		silent! call delete(outname)
	endif
	silent! call delete(tmpname)
	let textlist = []
	for text in hr
		let text = substitute(text, '\r$', '', 'g')
		let textlist += [text]
	endfor
	return textlist
endfunc


"----------------------------------------------------------------------
" replace the text from range
"----------------------------------------------------------------------
function! asclib#core#text_replace(bid, lnum, count, program, opts) abort
	if a:count <= 0
		return 0
	endif
	if type(a:bid) == 0
		let bid = (a:bid >= 0)? bufnr(a:bid) : (bufnr(''))
	else
		let bid = bufnr(a:bid)
	endif
	if !exists('*deletebufline')
		if bid != bufnr('')
			return -1
		endif
	endif
	let current = (bid == bufnr(''))? 1 : 0
	" let current = exists('*deletebufline')? 0 : current
	if current
		let text = getline(a:lnum, a:lnum + a:count - 1)
	else
		let text = getbufline(bid, a:lnum, a:lnum + a:count - 1)
	endif
	if type(a:program) == v:t_string
		if a:program =~ '^\s*:'
			let funname = matchstr(a:program, '^\s*:\zs.*$')
			let hr = call(funname, [text])
		else
			let encoding = get(a:opts, 'encoding', '')
			let cwd = get(a:opts, 'cwd', '')
			let s:shell_error = 0
			let hr = asclib#core#text_process(a:program, text, cwd, encoding)
			if s:shell_error != 0
				if get(a:opts, 'strict', 0) != 0
					let g:asclib#core#filter_error = hr
					return -1
				endif
			endif
		endif
	elseif type(a:program) == v:t_func
		let hr = call(a:program, [text])
	endif
	if current
		if len(text) < len(hr)
			call append(a:lnum, repeat([''], len(hr) - len(text)))
		elseif len(text) > len(hr)
			let endup = a:lnum + len(text) - len(hr) - 1
			silent! exec printf('%d,%dd', a:lnum, endup)
		endif
		call setline(a:lnum, hr)
		return 0
	endif
	if len(text) < len(hr)
		call appendbufline(bid, a:lnum, repeat([''], len(hr) - len(text)))
	elseif len(text) > len(hr)
		let endup = a:lnum + len(text) - len(hr) - 1
		silent call deletebufline(bid, a:lnum, endup)
	endif
	call setbufline(bid, a:lnum, hr)
	return 0
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
" returns [opts, args]
"----------------------------------------------------------------------
function! asclib#core#getopt(args)
	let opts = {}
	let args = []
	let mode = 0
	for p in a:args
		let p = substitute(p, '^\s*\(.\{-}\)\s*$', '\1', '')
		if mode == 0
			if p == '--'
				let mode = 1
			elseif p =~ '^[+-]'
				let key = p
				let val = ''
				let pos = stridx(p, '=')
				if pos >= 0
					let key = strpart(p, 0, pos)
					let val = strpart(p, pos + 1)
				endif
				let key = substitute(key, '^\s*\(.\{-}\)\s*$', '\1', '')
				let val = substitute(val, '^\s*\(.\{-}\)\s*$', '\1', '')
				if len(key) > 1
					let opts[key] = val
				endif
			else
				let args += [p]
				let mode = 1
			endif
		else
			let args += [p]
		endif
	endfor
	return [opts, args]
endfunc


"----------------------------------------------------------------------
" write script
"----------------------------------------------------------------------
function! asclib#core#writefile(lines, name)
	if v:version >= 700
		call writefile(a:lines, a:name)
	else
		exe 'redir ! > '.fnameescape(a:name)
		for index in range(len(a:line))
			silent echo a:line[index]
		endfor
		redir END
	endif
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


"----------------------------------------------------------------------
" simulate time.time()
"----------------------------------------------------------------------
function! asclib#core#time()
	return reltimefloat(reltime())
endfunc


"----------------------------------------------------------------------
" clock since start
"----------------------------------------------------------------------
function! asclib#core#clock()
	if !exists('s:__clock_start')
		let s:__clock_start = asclib#core#time()
	endif
	return asclib#core#time() - s:__clock_start
endfunc


"----------------------------------------------------------------------
" safe print
"----------------------------------------------------------------------
function! asclib#core#print(content, highlight, ...)
	let saveshow = &showmode
	set noshowmode
    let wincols = &columns
    let statusline = (&laststatus==1 && winnr('$')>1) || (&laststatus==2)
    let reqspaces_lastline = (statusline || !&ruler) ? 12 : 29
    let width = len(a:content)
    let limit = wincols - reqspaces_lastline
	let l:content = a:content
	if width + 1 > limit
		let l:content = strpart(l:content, 0, limit - 1)
		let width = len(l:content)
	endif
	" prevent scrolling caused by multiple echo
	let needredraw = (a:0 >= 1)? a:1 : 1
	if needredraw != 0
		redraw 
	endif
	if a:highlight != 0
		echohl Type
		echo l:content
		echohl NONE
	else
		echo l:content
	endif
	if saveshow != 0
		set showmode
	endif
endfunc


