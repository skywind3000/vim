" file system library
"
" Maintainer:    The Vim Project <https://github.com/vim/vim> 
" Last Modified: 2024/07/26 16:52:33



"----------------------------------------------------------------------
" internal variables
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')
let s:sep = (s:windows != 0)? '\' : '/'


"----------------------------------------------------------------------
" return the base name of the given path
"----------------------------------------------------------------------
function! dist#vim#fs#basename(file) abort
	return fnamemodify(a:file, ':t')
endfunction


"----------------------------------------------------------------------
" return the parent directory of the given path
"----------------------------------------------------------------------
function! dist#vim#fs#dirname(file) abort
	return fnamemodify(a:file, ':h')
endfunction


"----------------------------------------------------------------------
" Return 1 if path is an absolute pathname, or 0 if it is a relative
"----------------------------------------------------------------------
function! dist#vim#fs#isabs(path)
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
endfunction


"----------------------------------------------------------------------
" join two path
"----------------------------------------------------------------------
function! s:path_join(home, name) abort
	let l:size = strlen(a:home)
	if l:size == 0 | return a:name | endif
	if dist#vim#fs#isabs(a:name)
		return a:name
	endif
	let l:last = strpart(a:home, l:size - 1, 1)
	if has("win32") || has("win64") || has("win16") || has('win95')
		if l:last == "/" || l:last == "\\"
			return a:home . a:name
		else
			return a:home . '\' . a:name
		endif
	else
		if l:last == "/"
			return a:home . a:name
		else
			return a:home . '/' . a:name
		endif
	endif
endfunction


"----------------------------------------------------------------------
" Concatenate directories and/or file paths into a single path
"----------------------------------------------------------------------
function! dist#vim#fs#joinpath(...) abort
	let t = ''
	for p in a:000
		let t = s:path_join(t, p)
	endfor
	return t
endfunction


