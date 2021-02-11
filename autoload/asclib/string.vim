"======================================================================
"
" string.vim - 
"
" Created by skywind on 2018/04/25
" Last Modified: 2018/04/25 16:09:39
"
"======================================================================


"----------------------------------------------------------------------
" string replace
"----------------------------------------------------------------------
function! asclib#string#replace(text, old, new)
	let data = split(a:text, a:old, 1)
	return join(data, a:new)
endfunc


"----------------------------------------------------------------------
" string strip
"----------------------------------------------------------------------
function! asclib#string#strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)[\s\r\n]*$', '\1', '')
endfunc


"----------------------------------------------------------------------
" string partition 
"----------------------------------------------------------------------
function! asclib#string#partition(text, sep)
	let pos = stridx(a:text, a:sep)
	if pos < 0
		return [a:text, '', '']
	else
		let size = strlen(a:sep)
		let head = strpart(a:text, 0, pos)
		let sep = strpart(a:text, pos, size)
		let tail = strpart(a:text, pos + size)
		return [head, sep, tail]
	endif
endfunc

