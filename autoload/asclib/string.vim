"======================================================================
"
" string.vim - 
"
" Created by skywind on 2018/04/25
" Last Modified: 2022/09/01 21:08
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
	return substitute(a:text, '^\s*\(.\{-}\)[\t\r\n ]*$', '\1', '')
endfunc


"----------------------------------------------------------------------
" strip left
"----------------------------------------------------------------------
function! asclib#string#lstrip(text)
	return substitute(a:text, '^\s*', '', '')
endfunc


"----------------------------------------------------------------------
" strip left
"----------------------------------------------------------------------
function! asclib#string#rstrip(text)
	return substitute(a:text, '[\t\r\n ]*$', '', '')
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


"----------------------------------------------------------------------
" starts with prefix
"----------------------------------------------------------------------
function! asclib#string#startswith(text, prefix)
	return (empty(a:prefix) || (stridx(a:text, a:prefix) == 0))
endfunc


"----------------------------------------------------------------------
" ends with suffix
"----------------------------------------------------------------------
function! asclib#string#endswith(text, suffix)
	let s1 = len(a:text)
	let s2 = len(a:suffix)
	let ss = s1 - s2
	if s1 < s2
		return 0
	endif
	return (empty(a:suffix) || (stridx(a:text, a:suffix, ss) == ss))
endfunc


"----------------------------------------------------------------------
" check if text contains part
"----------------------------------------------------------------------
function! asclib#string#contains(text, part)
	return (stridx(a:text, a:part) >= 0)? 1 : 0
endfunc


"----------------------------------------------------------------------
" get range
"----------------------------------------------------------------------
function! asclib#string#between(text, begin, endup, ...)
	let pos = (a:0 > 0)? (a:1) : 0
	let p1 = stridx(a:text, a:begin, pos)
	if p1 < 0
		return [-1, -1]
	endif
	let p1 = p1 + len(a:begin)
	let p2 = stridx(a:text, a:endup, p1)
	if p2 < 0
		return [-1, -1]
	endif
	return [p1, p2]
endfunc


"----------------------------------------------------------------------
" return matched text at certain position
"----------------------------------------------------------------------
function! asclib#string#matchat(text, pattern, position)
	let start = match(a:text, a:pattern, 0)
	while (start >= 0) && (start <= a:position)
		let endup = matchend(a:text, a:pattern, start)
		if (start <= a:position) && (endup > a:position)
			return [start, endup, strpart(a:text, start, endup - start)]
		else
			let start = match(a:text, a:pattern, endup)
		endif
	endwhile
	return [-1, -1, '']
endfunc


"----------------------------------------------------------------------
" eval & expand: '%{script}' in string
"----------------------------------------------------------------------
function! asclib#string#expand(string) abort
	let partial = []
	let index = 0
	while 1
		let pos = stridx(a:string, '%{', index)
		if pos < 0
			let partial += [strpart(a:string, index)]
			break
		endif
		let head = ''
		if pos > index
			let partial += [strpart(a:string, index, pos - index)]
		endif
		let endup = stridx(a:string, '}', pos + 2)
		if endup < 0
			let partial += [strpart(a:stirng, index)]
			break
		endif
		let index = endup + 1
		if endup > pos + 2
			let script = strpart(a:string, pos + 2, endup - (pos + 2))
			let script = substitute(script, '^\s*\(.\{-}\)\s*$', '\1', '')
			let result = eval(script)
			let partial += [result]
		endif
	endwhile
	return join(partial, '')
endfunc


"----------------------------------------------------------------------
" ask user input to replace each %{NAME} in string
"----------------------------------------------------------------------
function! asclib#string#prompt(string) abort
	let partial = []
	let index = 0
	while 1
		let pos = stridx(a:string, '%{', index)
		if pos < 0
			let partial += [strpart(a:string, index)]
			break
		endif
		let head = ''
		if pos > index
			let partial += [strpart(a:string, index, pos - index)]
		endif
		let endup = stridx(a:string, '}', pos + 2)
		if endup < 0
			let partial += [strpart(a:stirng, index)]
			break
		endif
		let index = endup + 1
		if endup > pos + 2
			let script = strpart(a:string, pos + 2, endup - (pos + 2))
			let script = substitute(script, '^\s*\(.\{-}\)\s*$', '\1', '')
			let varname = script
			let default = ""
			let pos = stridx(script, '=')
			if pos >= 0
				let varname = strpart(script, 0, pos)
				let default = strpart(script, pos + 1)
			endif
			if varname == ''
				if default != ''
					let result = eval(devault)
				endif
			else
				redraw
				call inputsave()
				try
					let result = input('input ('.varname.'): ', default)
				catch /^Vim:Interrupt$/
					let result = ''
				endtry
				call inputrestore()
				redraw
				if result == ''
					return ''
				endif
			endif
			let partial += [result]
		endif
	endwhile
	return join(partial, '')
endfunc



