"======================================================================
"
" path.vim - 
"
" Created by skywind on 2018/04/25
" Last Modified: 2021/02/14 19:14
"
"======================================================================

let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h:h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')

let asclib#path#windows = s:windows


"----------------------------------------------------------------------
" change directory in proper way
"----------------------------------------------------------------------
function! asclib#path#chdir(path)
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? 'lcd' : 'cd'
	endif
	silent execute cmd . ' '. fnameescape(a:path)
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
		if &bt == 'terminal' || &bt == 'nofile'
			let f = ''
		endif
	elseif f =~ '^\~[\/\\]'
		let f = expand(f)
	endif
	let f = fnamemodify(f, ':p')
	if s:windows
		let f = substitute(f, "\\", '/', 'g')
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
		let head = strpart(path, 1, 2)
		if head == ':/' || head == ":\\"
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
" full file name
"----------------------------------------------------------------------
function! asclib#path#fullname(f)
	return asclib#path#abspath(a:f)
endfunc


"----------------------------------------------------------------------
" dirname
"----------------------------------------------------------------------
function! asclib#path#dirname(path)
	return fnamemodify(a:path, ':h')
endfunc


"----------------------------------------------------------------------
" normalize
"----------------------------------------------------------------------
function! asclib#path#normalize(path, ...)
	let lower = (a:0 > 0)? a:1 : 0
	let path = a:path
	if s:windows
		let path = tr(path, "\\", '/')
	endif
	if lower && (s:windows || has('win32unix'))
		let path = tolower(path)
	endif
	let size = len(path)
	if path[size - 1] == '/'
		let path = strpart(path, 0, size - 1)
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
	let p1 = asclib#path#normcase(asclib#path#abspath(a:path1))
	let p2 = asclib#path#normcase(asclib#path#abspath(a:path2))
	return (p1 == p2)? 1 : 0
endfunc


"----------------------------------------------------------------------
" path asc home
"----------------------------------------------------------------------
function! asclib#path#runtime(path)
	let pathname = fnamemodify(s:scripthome, ':h')
	let pathname = asclib#path#join(pathname, a:path)
	let pathname = fnamemodify(pathname, ':p')
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
" find project root
"----------------------------------------------------------------------
function! s:find_root(path, markers, strict)
	function! s:guess_root(filename, markers)
		let fullname = asclib#path#fullname(a:filename)
		if fullname =~ '^fugitive:/'
			if exists('b:git_dir')
				return fnamemodify(b:git_dir, ':h')
			endif
			return '' " skip any fugitive buffers early
		endif
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
	if a:path == '%'
		if exists('b:asyncrun_root') && b:asyncrun_root != ''
			return b:asyncrun_root
		elseif exists('t:asyncrun_root') && t:asyncrun_root != ''
			return t:asyncrun_root
		elseif exists('g:asyncrun_root') && g:asyncrun_root != ''
			return g:asyncrun_root
		endif
	endif
	let root = s:guess_root(a:path, a:markers)
	if root != ''
		return asclib#path#abspath(root)
	elseif a:strict != 0
		return ''
	endif
	" Not found: return parent directory of current file / file itself.
	let fullname = asclib#path#abspath(a:path)
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
	let l:hr = s:find_root(a:path, markers, strict)
	if s:windows != 0
		let l:hr = join(split(l:hr, '/', 1), "\\")
	endif
	return l:hr
endfunc


"----------------------------------------------------------------------
" exists
"----------------------------------------------------------------------
function! asclib#path#exists(path)
	if isdirectory(a:path)
		return 1
	elseif filereadable(a:path)
		return 1
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" strip ending slash
"----------------------------------------------------------------------
function! asclib#path#stripslash(path)
	return fnamemodify(a:path, ':s?[/\\]$??')
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
function! asclib#path#push_dir(path)
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
function! asclib#path#pop_dir()
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
" check
"----------------------------------------------------------------------
function! asclib#path#busybox(exename, ...)
	if !exists('g:asc_busybox')
		let g:asc_busybox = 'busybox'
		if asclib#path#executable('busybox') == ''
			let g:asc_busybox = ''
		endif
	endif
	if !exists('s:busybox')
		let s:busybox = [{}, {}, {}, {}]
	endif
	let mode = get(g:, 'asc_busybox_mode', 0)
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
	if g:asc_busybox != ''
		let path = g:asc_busybox . ' ' . a:exename
	endif
	let s:busybox[1][a:exename] = path
	return path
endfunc


