"======================================================================
"
" path.vim - 
"
" Created by skywind on 2018/04/25
" Last Modified: 2018/04/25 15:46:44
"
"======================================================================

let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h:h')
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')


"----------------------------------------------------------------------
" join two path
"----------------------------------------------------------------------
function! asclib#path#join(home, name)
    let l:size = strlen(a:home)
    if l:size == 0 | return a:name | endif
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
" path asc home
"----------------------------------------------------------------------
function! asclib#path#runtime(path)
	let pathname = fnamemodify(s:scripthome, ':h')
	let pathname = asclib#path#join(pathname, a:path)
	let pathname = fnamemodify(pathname, ':p')
	return substitute(pathname, '\\', '/', 'g')
endfunc


"----------------------------------------------------------------------
" find project root
"----------------------------------------------------------------------
function! s:find_root(path, markers)
    function! s:guess_root(filename, markers)
        let fullname = vimmake#fullname(a:filename)
        if exists('b:asclib_path_root')
            return b:asclib_path_root
        endif
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
				if filereadable(newname)
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
	let root = s:guess_root(a:path, a:markers)
	if len(root)
		return asclib#path#abspath(root)
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
		let markers = a:1
	endif
	let l:hr = s:find_root(a:path, markers)
	if s:windows != 0
		let l:hr = join(split(l:hr, '/', 1), "\\")
	endif
	return l:hr
endfunc



