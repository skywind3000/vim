"======================================================================
"
" path.vim - 
"
" Created by skywind on 2020/01/15
" Last Modified: 2020/01/15 12:01:02
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h:h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')

let quicktask#path#windows = s:windows


"----------------------------------------------------------------------
" change directory in proper way
"----------------------------------------------------------------------
function! quicktask#path#chdir(path)
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
function! quicktask#path#abspath(path)
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
	let f = (f != '%')? f : expand('%')
	let f = fnamemodify(f, ':p')
	if s:windows != 0
		let f = substitute(f, "\\", '/', 'g')
	endif
	if len(f) > 1
		let size = len(f)
		if f[size - 1] == '/'
			let f = strpart(f, 0, size - 1)
		endif
	endif
	return f
endfunc


"----------------------------------------------------------------------
" check absolute path name
"----------------------------------------------------------------------
function! quicktask#path#isabs(path)
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
function! quicktask#path#join(home, name)
    let l:size = strlen(a:home)
    if l:size == 0 | return a:name | endif
	if quicktask#path#isabs(a:name)
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
function! quicktask#path#fullname(f)
	let f = a:f
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
	let f = (f != '%')? f : expand('%')
	let f = fnamemodify(f, ':p')
	if has('win32') || has('win64') || has('win16') || has('win95')
		let f = substitute(f, "\\", '/', 'g')
	endif
	if len(f) > 1
		let size = len(f)
		if f[size - 1] == '/'
			let f = strpart(f, 0, size - 1)
		endif
	endif
	return f
endfunc


"----------------------------------------------------------------------
" dirname
"----------------------------------------------------------------------
function! quicktask#path#dirname(path)
	return fnamemodify(a:path, ':h')
endfunc


"----------------------------------------------------------------------
" normalize
"----------------------------------------------------------------------
function! quicktask#path#normalize(path, ...)
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
" returns 1 for equal, 0 for not equal
"----------------------------------------------------------------------
function! quicktask#path#equal(path1, path2)
	let p1 = quicktask#path#abspath(a:path1)
	let p2 = quicktask#path#abspath(a:path2)
	if s:windows || has('win32unix')
		let p1 = tolower(p1)
		let p2 = tolower(p2)
	endif
	if p1 == p2
		return 1
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" path asc home
"----------------------------------------------------------------------
function! quicktask#path#runtime(path)
	let pathname = fnamemodify(s:scripthome, ':h')
	let pathname = quicktask#path#join(pathname, a:path)
	let pathname = fnamemodify(pathname, ':p')
	return substitute(pathname, '\\', '/', 'g')
endfunc


"----------------------------------------------------------------------
" find files in path
"----------------------------------------------------------------------
function! quicktask#path#which(name)
	if has('win32') || has('win64') || has('win16') || has('win95')
		let sep = ';'
	else
		let sep = ':'
	endif
	if quicktask#path#isabs(a:name)
		if filereadable(a:name)
			return quicktask#path#abspath(a:name)
		endif
	endif
	for path in split($PATH, sep)
		let filename = quicktask#path#join(path, a:name)
		if filereadable(filename)
			return quicktask#path#abspath(filename)
		endif
	endfor
	return ''
endfunc


"----------------------------------------------------------------------
" find executable
"----------------------------------------------------------------------
function! quicktask#path#executable(name)
	if s:windows != 0
		for n in ['.exe', '.cmd', '.bat', '.vbs']
			let nname = a:name . n
			let npath = quicktask#path#which(nname)
			if npath != ''
				return npath
			endif
		endfor
	else
		return quicktask#path#which(a:name)
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" find root
"----------------------------------------------------------------------
function! quicktask#path#find_root(name, markers)
	let name = fnamemodify((a:name != '')? a:name : bufname(), ':p')
	let finding = ''
	" iterate all markers
	for marker in a:markers
		if marker != ''
			" search as a file
			let x = findfile(marker, name . '/;')
			let x = (x == '')? '' : fnamemodify(x, ':p:h')
			" search as a directory
			let y = finddir(marker, name . '/;')
			let y = (y == '')? '' : fnamemodify(y, ':p:h:h')
			" which one is the nearest directory ?
			let z = (strchars(x) > strchars(y))? x : y
			" keep the nearest one in finding
			let finding = (strchars(z) > strchars(finding))? z : finding
		endif
	endfor
	return (finding == '')? '' : fnamemodify(finding, ':p')
endfunc


"----------------------------------------------------------------------
" get project root
"----------------------------------------------------------------------
function! quicktask#path#project_root(name, ...)
	let name = fnamemodify((a:name != '')? a:name : bufname(), ':p')
	let markers = ['.project', '.git', '.hg', '.svn', '.root']
	if exists('g:quicktask_rootmarks')
		let markers = g:quicktask_rootmarks
	endif
	let root = quicktask#path#find_root(name, markers)
	if root == ''
		let strict = (a:0 >= 1)? a:1 : 0
		if strict == 0
			return isdirectory(name)? name : fnamemodify(name, ':h')
		endif
	endif
	return root
endfunc



