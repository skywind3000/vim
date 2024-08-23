"======================================================================
"
" ini.vim - 
"
" Created by skywind on 2020/01/15
" Last Modified: 2020/01/15 17:16:42
"
"======================================================================


"----------------------------------------------------------------------
" parse ini
"----------------------------------------------------------------------
function! asclib#ini#read(source)
	if type(a:source) == type('')
		if !filereadable(a:source)
			return -1
		endif
		let content = readfile(a:source)
	elseif type(a:source) == type([])
		let content = a:source
	else
		return -2
	endif
	let sections = {}
	let current = 'default'
	let index = 0
	for line in content
		let t = substitute(line, '^\s*\(.\{-}\)\s*$', '\1', '')
		let index += 1
		if t == ''
			continue
		elseif t =~ '^[;#].*$'
			continue
		elseif t =~ '^\[.*\]$'
			let current = substitute(t, '^\[\s*\(.\{-}\)\s*\]$', '\1', '')
			if !has_key(sections, current)
				let sections[current] = {}
			endif
		else
			let pos = stridx(t, '=')
			if pos >= 0
				let key = strpart(t, 0, pos)
				let val = strpart(t, pos + 1)
				let key = substitute(key, '^\s*\(.\{-}\)\s*$', '\1', '')
				let val = substitute(val, '^\s*\(.\{-}\)\s*$', '\1', '')
				if !has_key(sections, current)
					let sections[current] = {}
				endif
				let sections[current][key] = val
			endif
		endif
	endfor
	return sections
endfunc



"----------------------------------------------------------------------
" write to file
"----------------------------------------------------------------------
function! asclib#ini#save(filename, sections)
	let content = []
	let content += ['# vim: set ft=dosini:']
	let content += ['']
	for sect in keys(a:sections)
		let section = a:sections[sect]
		let content += ['[' . sect . ']']
		for key in keys(section)
			let content += [key . '=' . section[key]]
		endfor
		let content += ['']
	endfor
	call writefile(content, a:filename)
endfunc



