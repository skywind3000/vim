"======================================================================
"
" minibox.vim - 
"
" Created by skywind on 2020/01/01
" Last Modified: 2020/01/01 03:44:53
"
"======================================================================

let s:windows = has('win32') || has('win64') || has('win16') || has('win95')

function! minibox#clear_leader_mru()
	if s:windows == 0
		return 0
	endif
	let fn = expand('~/.vim/cache/.LfCache/python3/mru/mruCache')
	let content = []
	let avail = {}
	if !filereadable(fn)
		let fn = expand('~/.vim/cache/.LfCache/python2/mru/mruCache')
		if !filereadable(expand(fn))
			return -1
		endif
	endif
	for name in readfile(fn)
		let name = substitute(name, '/', '\\', 'g')
		let name = substitute(name, '\n*$', '', 'g')
		let key = tolower(name)
		if !has_key(avail, key)
			let avail[key] = 1
			let content += [name]
		endif
	endfor
	call writefile(content, fn)
endfunc



