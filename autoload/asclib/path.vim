"======================================================================
"
" path.vim - 
"
" Created by skywind on 2018/04/25
" Last Modified: 2023/08/10 18:03
"
"======================================================================

let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h:h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')

let asclib#path#windows = s:windows

let s:has_native_isabs = exists('*isabsolutepath')


"----------------------------------------------------------------------
" change directory in proper way
"----------------------------------------------------------------------
function! asclib#path#chdir(path)
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
function! asclib#path#getcd()
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	return cmd
endfunc


"----------------------------------------------------------------------
" change dir with noautocmd prefix
"----------------------------------------------------------------------
function! asclib#path#chdir_noautocmd(path)
	noautocmd call asclib#path#chdir(a:path)
endfunc


"----------------------------------------------------------------------
" absolute path
"----------------------------------------------------------------------
function! asclib#path#abspath(path)
	let f = a:path
	if f =~ "'."
		try
			redir => m
			silent exe ':marks' f[1]
			redir END
			let f = split(split(m, '\n')[-1])[-1]
			let f = filereadable(f)? f : ''
		catch
			let f = '%'
		endtry
	endif
	if f == '%'
		let f = expand('%')
		if &bt == 'terminal'
			let f = ''
		elseif &bt != ''
			let is_directory = 0
			if f =~ '\v^fugitive\:[\\\/][\\\/][\\\/]'
				return asclib#path#abspath(f)
			elseif f =~ '[\/\\]$'
				if f =~ '^[\/\\]' || f =~ '^.:[\/\\]'
					let is_directory = isdirectory(f)
				endif
			endif
			let f = (is_directory)? f : ''
		endif
	elseif f =~ '^\~[\/\\]'
		let f = expand(f)
	elseif f =~ '\v^fugitive\:[\\\/][\\\/][\\\/]'
		let path = strpart(f, s:windows? 12 : 11)
		let pos = stridx(path, '.git')
		if pos >= 0
			let path = strpart(path, 0, pos)
		endif
		let f = fnamemodify(path, ':h')
	endif
	let f = fnamemodify(f, ':p')
	if s:windows
		let f = tr(f, '\', '/')
		let h = matchstr(f, '\v^[\/\\]+')
		let b = strpart(f, strlen(h))
		let f = h . substitute(b, '\v[\/\\]+', '/', 'g')
	else
		let f = substitute(f, '\v[\/\\]+', '/', 'g')
	endif
	if f =~ '\/$'
		let f = fnamemodify(f, ':h')
	endif
	return f
endfunc


"----------------------------------------------------------------------
" check absolute path name
"----------------------------------------------------------------------
function! asclib#path#isabs(path)
	let path = a:path
	if strpart(path, 0, 1) == '~'
		return 1
	endif
	if s:windows != 0
		if path =~ '^.:[\/\\]'
			return 1
		endif
		let head = strpart(path, 0, 1)
		if head == "\\"
			return 1
		endif
	endif
	let head = strpart(path, 0, 1)
	if head == '/'
		return 1
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" join two path
"----------------------------------------------------------------------
function! asclib#path#join(home, name)
	let l:size = strlen(a:home)
	if l:size == 0 | return a:name | endif
	if asclib#path#isabs(a:name)
		return a:name
	endif
	let l:last = strpart(a:home, l:size - 1, 1)
	if has("win32") || has("win64") || has("win16") || has('win95')
		if l:last == "/" || l:last == "\\"
			return a:home . a:name
		else
			return a:home . '/' . a:name
		endif
	else
		if l:last == "/"
			return a:home . a:name
		else
			return a:home . '/' . a:name
		endif
	endif
endfunc


"----------------------------------------------------------------------
" dirname
"----------------------------------------------------------------------
function! asclib#path#dirname(path)
	return fnamemodify(a:path, ':h')
endfunc


"----------------------------------------------------------------------
" basename of /foo/bar is bar
"----------------------------------------------------------------------
function! asclib#path#basename(path)
	return fnamemodify(a:path, ':t')
endfunc


"----------------------------------------------------------------------
" normalize
"----------------------------------------------------------------------
function! asclib#path#normalize(path, ...)
	let lower = (a:0 > 0)? a:1 : 0
	let path = a:path
	if (s:windows == 0 && path == '/') || (s:windows && path =~ '^.:[\/\\]')
		let path = fnamemodify(path, ':p')
	else
		if s:windows == 0 || (s:windows && path !~ '^.:')
			let path = fnamemodify(path, ':.')
		endif
	endif
	if s:windows
		let path = tr(path, "\\", '/')
	endif
	if lower && (s:windows || has('win32unix'))
		let path = tolower(path)
	endif
	if path =~ '^[\/\\]$'
		return path
	elseif s:windows && path =~ '^.:[\/\\]$'
		return path
	endif
	if s:windows
		let path = tr(path, '\', '/')
		let h = matchstr(path, '\v^[\/\\]+')
		let b = strpart(path, strlen(h))
		let path = h . substitute(b, '\v[\/\\]+', '/', 'g')
	else
		let path = substitute(path, '\v[\/\\]+', '/', 'g')
	endif
	let size = len(path)
	if size > 1 && path[size - 1] == '/'
		let path = fnamemodify(path, ':h')
	endif
	return path
endfunc


"----------------------------------------------------------------------
" normal case
"----------------------------------------------------------------------
function! asclib#path#normcase(path)
	if s:windows == 0
		return (has('win32unix') == 0)? (a:path) : tolower(a:path)
	else
		return tolower(tr(a:path, '/', '\'))
	endif
endfunc


"----------------------------------------------------------------------
" returns 1 for equal, 0 for not equal
"----------------------------------------------------------------------
function! asclib#path#equal(path1, path2)
	if a:path1 == a:path2
		return 1
	endif
	let p1 = asclib#path#normcase(asclib#path#abspath(a:path1))
	let p2 = asclib#path#normcase(asclib#path#abspath(a:path2))
	return (p1 == p2)? 1 : 0
endfunc


"----------------------------------------------------------------------
" return 1 if base directory contains child, 0 for not contain
"----------------------------------------------------------------------
function! asclib#path#contains(base, child)
	let base = asclib#path#abspath(a:base)
	let child = asclib#path#abspath(a:child)
	let base = asclib#path#normalize(base) . '/'
	let child = asclib#path#normalize(child)
	let base = asclib#path#normcase(base)
	let child = asclib#path#normcase(child)
	return (stridx(child, base) == 0)? 1 : 0
endfunc


"----------------------------------------------------------------------
" return a relative version of a path
"----------------------------------------------------------------------
function! asclib#path#relpath(path, base) abort
	let path = asclib#path#abspath(a:path)
	let base = asclib#path#abspath(a:base)
	let path = asclib#path#normalize(path)
	let base = asclib#path#normalize(base)
	let head = ''
	while 1
		if asclib#path#contains(base, path)
			if base =~ '[\/\\]$'
				let size = strlen(base)
			else
				let size = strlen(base) + 1
			endif
			return head . strpart(path, size)
		endif
		let prev = base
		let head = '../' . head
		let base = fnamemodify(base, ':h')
		if base == prev
			break
		endif
	endwhile
	return ''
endfunc


"----------------------------------------------------------------------
" python: os.path.split
"----------------------------------------------------------------------
function! asclib#path#split(path)
	let p1 = fnamemodify(a:path, ':h')
	let p2 = fnamemodify(a:path, ':t')
	return [p1, p2]
endfunc


"----------------------------------------------------------------------
" split ext
"----------------------------------------------------------------------
function! asclib#path#splitext(path)
	let path = a:path
	let size = strlen(path)
	let pos = strridx(path, '.')
	if pos < 0
		return [path, '']
	endif
	let p1 = strridx(path, '/')
	if s:windows
		let p2 = strridx(path, '\')
		let p1 = (p1 > p2)? p1 : p2
	endif
	if p1 > pos
		return [path, '']
	endif
	let main = strpart(path, 0, pos)
	let ext = strpart(path, pos)
	return [main, ext]
endfunc


"----------------------------------------------------------------------
" strip ending slash
"----------------------------------------------------------------------
function! asclib#path#stripslash(path)
	if a:path =~ '\v[\/\\]$'
		return fnamemodify(a:path, ':h')
	endif
	return a:path
endfunc


"----------------------------------------------------------------------
" path asc home
"----------------------------------------------------------------------
function! asclib#path#runtime(path)
	let pathname = fnamemodify(s:scripthome, ':h')
	let pathname = asclib#path#join(pathname, a:path)
	let pathname = asclib#path#abspath(pathname)
	return tr(pathname, '\', '/')
endfunc


"----------------------------------------------------------------------
" find files in path
"----------------------------------------------------------------------
function! asclib#path#which(name)
	if has('win32') || has('win64') || has('win16') || has('win95')
		let sep = ';'
	else
		let sep = ':'
	endif
	if asclib#path#isabs(a:name)
		if filereadable(a:name)
			return asclib#path#abspath(a:name)
		endif
	endif
	for path in split($PATH, sep)
		let filename = asclib#path#join(path, a:name)
		if filereadable(filename)
			return asclib#path#abspath(filename)
		endif
	endfor
	return ''
endfunc


"----------------------------------------------------------------------
" find executable
"----------------------------------------------------------------------
function! asclib#path#executable(name)
	if s:windows != 0
		for n in ['.exe', '.cmd', '.bat', '.vbs']
			let nname = a:name . n
			let npath = asclib#path#which(nname)
			if npath != ''
				return npath
			endif
		endfor
	else
		return asclib#path#which(a:name)
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" guess root
"----------------------------------------------------------------------
function! s:guess_root(filename, markers)
	let fullname = asclib#path#abspath(a:filename)
	let pivot = fullname
	if !isdirectory(pivot)
		let pivot = fnamemodify(pivot, ':h')
	endif
	while 1
		let prev = pivot
		for marker in a:markers
			let newname = asclib#path#join(pivot, marker)
			if newname =~ '[\*\?\[\]]'
				if glob(newname) != ''
					return pivot
				endif
			elseif filereadable(newname)
				return pivot
			elseif isdirectory(newname)
				return pivot
			endif
		endfor
		let pivot = fnamemodify(pivot, ':h')
		if pivot == prev
			break
		endif
	endwhile
	return ''
endfunc


"----------------------------------------------------------------------
" find project root
"----------------------------------------------------------------------
function! s:find_root(name, markers, strict)
	let path = ''
	if type(a:name) == 0
		let bid = (a:name < 0)? bufnr('%') : (a:name + 0)
		let path = bufname(bid)
		let root = getbufvar(bid, 'asyncrun_root', '')
		if root != ''
			return root
		elseif exists('g:asyncrun_root') && g:asyncrun_root != ''
			return g:asyncrun_root
		elseif exists('g:asyncrun_locator')
			let root = call(g:asyncrun_locator, [bid])
			if root != ''
				return root
			endif
		endif
		if getbufvar(bid, '&buftype') != ''
			let path = getcwd()
			return asclib#path#abspath(path)
		endif
	elseif a:name == '%'
		let path = a:name
		if exists('b:asyncrun_root') && b:asyncrun_root != ''
			return b:asyncrun_root
		elseif exists('t:asyncrun_root') && t:asyncrun_root != ''
			return t:asyncrun_root
		elseif exists('g:asyncrun_root') && g:asyncrun_root != ''
			return g:asyncrun_root
		elseif exists('g:asyncrun_locator')
			let root = call(g:asyncrun_locator, [a:name])
			if root != ''
				return root
			endif
		endif
	else
		let path = printf('%s', a:name)
	endif
	let root = s:guess_root(path, a:markers)
	if root != ''
		return asclib#path#abspath(root)
	elseif a:strict != 0
		return ''
	endif
	" Not found: return parent directory of current file / file itself.
	let fullname = asclib#path#abspath(path)
	if isdirectory(fullname)
		return fullname
	endif
	return asclib#path#abspath(fnamemodify(fullname, ':h'))
endfunc


"----------------------------------------------------------------------
" get project root
"----------------------------------------------------------------------
function! asclib#path#get_root(path, ...)
	let markers = ['.root', '.git', '.hg', '.svn', '.project']
	if exists('g:asclib_path_rootmarks')
		let markers = g:asclib_path_rootmarks
	endif
	if a:0 > 0
		if type(a:1) == type([])
			let markers = a:1
		endif
	endif
	let strict = (a:0 >= 2)? (a:2) : 0
	if type(a:path) == 0 && (a:path == 0)
		let l:hr = s:find_root('%', markers, strict)
	else
		let l:hr = s:find_root(a:path, markers, strict)
	endif
	if s:windows != 0
		let l:hr = join(split(l:hr, '/', 1), "\\")
	endif
	return l:hr
endfunc


"----------------------------------------------------------------------
" current root
"----------------------------------------------------------------------
function! asclib#path#current_root()
	return asclib#path#get_root('%')
endfunc


"----------------------------------------------------------------------
" exists
"----------------------------------------------------------------------
function! asclib#path#exists(path)
	if isdirectory(a:path)
		return 1
	elseif filereadable(a:path)
		return 1
	else
		if !empty(asclib#path#glob(a:path, 1))
			return 1
		endif
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" path to name
"----------------------------------------------------------------------
function! asclib#path#cachedir(cache_dir, root_dir, filename)
	if asclib#path#isabs(a:filename)
		return a:filename
	endif
	let l:file_path = asclib#path#stripslash(a:root_dir) . '/' . a:filename
	let cache_dir = a:cache_dir
	if cache_dir != ""
		" Put the tag file in the cache dir instead of inside the
		" project root.
		let l:file_path = cache_dir . '/' . tr(l:file_path, '\/: ', '---_')
		let l:file_path = substitute(l:file_path, '/\-', '/', '')
	endif
	let l:file_path = asclib#path#normalize(l:file_path)
	return l:file_path
endfunc


"----------------------------------------------------------------------
" push current dir in stack and switch dir to path
"----------------------------------------------------------------------
function! asclib#path#push(path)
	if !exists('s:dir_stack')
		let s:dir_stack = []
	endif
	let previous = getcwd()
	let s:dir_stack += [previous]
	call asclib#path#chdir(a:path)
	return previous
endfunc


"----------------------------------------------------------------------
" pop current dir in stack
"----------------------------------------------------------------------
function! asclib#path#pop()
	if !exists('s:dir_stack')
		let s:dir_stack = []
	endif
	let size = len(s:dir_stack)
	if size == 0
		return ''
	endif
	let previous = s:dir_stack[size - 1]
	call remove(s:dir_stack, size - 1)
	call asclib#path#chdir(previous)
	return previous
endfunc


"----------------------------------------------------------------------
" win2unix
"----------------------------------------------------------------------
function! asclib#path#win2unix(winpath, prefix)
	let prefix = a:prefix
	let path = a:winpath
	if path =~ '^\a:[/\\]'
		let drive = tolower(strpart(path, 0, 1))
		let name = strpart(path, 3)
		let p = asclib#path#join(prefix, drive)
		let p = asclib#path#join(p, name)
		return tr(p, '\', '/')
	elseif path =~ '^[/\\]'
		let drive = tolower(strpart(getcwd(), 0, 1))
		let name = strpart(path, 1)
		let p = asclib#path#join(prefix, drive)
		let p = asclib#path#join(p, name)
		return tr(p, '\', '/')
	else
		return tr(a:winpath, '\', '/')
	endif
endfunc


"----------------------------------------------------------------------
" check
"----------------------------------------------------------------------
function! asclib#path#busybox(exename, ...)
	if !exists('g:asclib_busybox')
		let g:asclib_busybox = 'busybox'
		if asclib#path#executable('busybox') == ''
			let g:asclib_busybox = ''
		endif
	endif
	if !exists('s:busybox')
		let s:busybox = [{}, {}, {}, {}]
	endif
	let mode = get(g:, 'asclib_busybox_mode', 0)
	let mode = (a:0 > 0)? (a:1) : mode
	let mode = (mode == 0)? 0 : 1
	if has_key(s:busybox[mode], a:exename)
		return s:busybox[mode][a:exename]
	endif
	let path = asclib#path#executable(a:exename)
	if mode == 0 && path != ''
		let s:busybox[0][a:exename] = a:exename
		return s:busybox[0][a:exename]
	endif
	if g:asclib_busybox != ''
		let path = g:asclib_busybox . ' ' . a:exename
	endif
	let s:busybox[1][a:exename] = path
	return path
endfunc


"----------------------------------------------------------------------
" expand path macro
"----------------------------------------------------------------------
function! asclib#path#expand_macros()
	let macros = {}
	let macros['VIM_FILEPATH'] = expand("%:p")
	let macros['VIM_FILENAME'] = expand("%:t")
	let macros['VIM_FILEDIR'] = expand("%:p:h")
	let macros['VIM_FILENOEXT'] = expand("%:t:r")
	let macros['VIM_PATHNOEXT'] = expand("%:p:r")
	let macros['VIM_FILEEXT'] = "." . expand("%:e")
	let macros['VIM_FILETYPE'] = (&filetype)
	let macros['VIM_CWD'] = getcwd()
	let macros['VIM_RELDIR'] = expand("%:h:.")
	let macros['VIM_RELNAME'] = expand("%:p:.")
	let macros['VIM_CWORD'] = expand("<cword>")
	let macros['VIM_CFILE'] = expand("<cfile>")
	let macros['VIM_CLINE'] = line('.')
	let macros['VIM_VERSION'] = ''.v:version
	let macros['VIM_SVRNAME'] = v:servername
	let macros['VIM_COLUMNS'] = ''.&columns
	let macros['VIM_LINES'] = ''.&lines
	let macros['VIM_GUI'] = has('gui_running')? 1 : 0
	let macros['VIM_ROOT'] = asclib#path#get_root('%')
	let macros['VIM_HOME'] = expand(split(&rtp, ',')[0])
	let macros['VIM_PRONAME'] = fnamemodify(macros['VIM_ROOT'], ':t')
	let macros['VIM_DIRNAME'] = fnamemodify(macros['VIM_CWD'], ':t')
	let macros['VIM_PROFILE'] = g:asynctasks_profile
	let macros['<cwd>'] = macros['VIM_CWD']
	let macros['<root>'] = macros['VIM_ROOT']
	if expand("%:e") == ''
		let macros['VIM_FILEEXT'] = ''
	endif
	if s:windows != 0
		let wslnames = ['FILEPATH', 'FILENAME', 'FILEDIR', 'FILENOEXT']
		let wslnames += ['PATHNOEXT', 'FILEEXT', 'FILETYPE', 'RELDIR']
		let wslnames += ['RELNAME', 'CFILE', 'ROOT', 'HOME', 'CWD']
		for name in wslnames
			let src = macros['VIM_' . name]
			let macros['WSL_' . name] = asclib#path#win2unix(src, '/mnt')
		endfor
	endif
	return macros
endfunc


"----------------------------------------------------------------------
" glob
"----------------------------------------------------------------------
function! asclib#path#glob(...)
	return call('glob', a:000)
endfunc


"----------------------------------------------------------------------
" globpath
"----------------------------------------------------------------------
function! asclib#path#globpath(...)
	if v:version == 704 && has('patch279') || v:version > 704
		return call('s:globpath', a:000)
	elseif v:version == 703 && has('patch465') || v:version > 703
		let l:list = (a:0 > 3 && a:4)
		let l:result = call('globpath', a:000[0:2])
		return (l:list ? split(l:result, '\n') : l:result)
	endif
endfunc


"----------------------------------------------------------------------
" filename pattern to regex pattern
"----------------------------------------------------------------------
function! asclib#path#pattern(pattern) abort
	let p = escape(a:pattern, "\\/'\".(){}^$%")
	let p = substitute(p, '?', '\.', 'g')
	return '^' . substitute(p, '\*', '\.\*', 'g') . '$'
endfunc


"----------------------------------------------------------------------
" fnmatch
"----------------------------------------------------------------------
function! asclib#path#fnmatch(filename, pattern) abort
	let p = asclib#path#pattern(a:pattern)
	let s = match(a:filename, p)
	return (s >= 0)? 1 : 0
endfunc


"----------------------------------------------------------------------
" usage: asclib#path#list(path [, pattern [, nosuf]])
"----------------------------------------------------------------------
function! asclib#path#list(path, ...)
	let fnpat = (a:0 > 0)? (a:1) : ''
	let nosuf = (a:0 > 1)? (a:2) : 0
	let path = expand(a:path)
	if !isdirectory(path)
		return []
	endif
	if fnpat != ''
		let fnpat = asclib#path#pattern(fnpat)
	endif
	let path = asclib#path#join(path, '*')
	let part = asclib#path#glob(path, nosuf)
	let candidate = []
	for n in split(part, "\n")
		let f = fnamemodify(n, ':t')
		if !empty(f)
			if fnpat != ''
				if match(f, fnpat) < 0
					continue
				endif
			endif
			let candidate += [f]
		endif
	endfor
	return candidate
endfunc


"----------------------------------------------------------------------
" search runtimepath: asclib#path#lookup('autoload/mode', '*.vim')
"----------------------------------------------------------------------
function! asclib#path#lookup(relpath, pattern) abort
	let result = []
	for root in split(&rtp, ',')
		if isdirectory(root)
			let test = asclib#path#join(root, a:relpath)
			for t in asclib#path#list(test, a:pattern)
				let n = asclib#path#join(test, t)
				if s:windows
					let n = tr(n, '/', '\')
				endif
				call add(result, n)
			endfor
		endif
	endfor
	return result
endfunc


"----------------------------------------------------------------------
" win path to msys path
"----------------------------------------------------------------------
function! asclib#path#msyspath(winpath)
	let abspath = asclib#path#abspath(a:winpath)
	return '/' . substitute(tr(abspath, '\', '/'), ':', '', 'g')
endfunc


"----------------------------------------------------------------------
" win path to cygpath
"----------------------------------------------------------------------
function! asclib#path#cygpath(winpath)
	let abspath = asclib#path#abspath(a:winpath)
	return '/cygdrive/' . substitute(tr(abspath, '\', '/'), ':', '', 'g')
endfunc


"----------------------------------------------------------------------
" shorten path
"----------------------------------------------------------------------
function! asclib#path#shorten(path, ...) abort
	let home = expand('~')
	let path = a:path
	let limit = (a:0 > 0)? a:1 : 40
	if asclib#path#contains(home, path)
		let size = strlen(home)
		let path = '~' . strpart(path, size)
	endif
	let size = strlen(path)
	if size > limit
		let t = pathshorten(path, 2)
		let size = strlen(t)
		if size > limit
			return pathshorten(path)
		endif
		return t
	endif
	return path
endfunc


