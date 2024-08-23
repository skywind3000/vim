"======================================================================
"
" mcm.vim - completion
"
" Created by skywind on 2023/08/03
" Last Modified: 2023/08/03 20:51:46
"
"======================================================================


"----------------------------------------------------------------------
" context before cursor
"----------------------------------------------------------------------
function! asclib#mcm#context() abort
	return strpart(getline('.'), 0, col('.') - 1)
endfunc


"----------------------------------------------------------------------
" check tailing space
"----------------------------------------------------------------------
function! asclib#mcm#check_space(context) abort
	return (a:context == '' || a:context =~ '\s\+$')? 1 : 0
endfunc


"----------------------------------------------------------------------
" filter list
"----------------------------------------------------------------------
function! asclib#mcm#match_list(list, prefix) abort
	let output = []
	let prefix = a:prefix
	for n in a:list
		if stridx(n, prefix) == 0
			call add(output, n)
		endif
	endfor
	return output
endfunc


"----------------------------------------------------------------------
" search candidate
"----------------------------------------------------------------------
function! asclib#mcm#match_complete(prefix, candidate, kind, sort) abort
	let prefix = a:prefix
	if type(a:candidate) == type({})
		let keys = keys(a:candidate)
		let matched = []
		for key in keys(a:candidate)
			if stridx(key, prefix) == 0
				call add(matched, key)
			endif
		endfor
		if a:sort
			call sort(matched)
		endif
		let output = []
		for key in matched
			let text = a:candidate[key]
			let item = {'word':key, 'kind': a:kind, 'menu':text}
			call add(output, item)
		endfor
		return output
	elseif type(a:candidate) == type([])
		let matched = []
		for item in a:candidate
			if type(item) == 1
				let name = item
				let text = ''
			elseif type(item) == 3
				if len(item) >= 2
					let name = item[0]
					let text = item[1]
				elseif len(item) == 1
					let name = item[0]
					let text = ''
				else
					continue
				endif
			else
				continue
			endif
			if stridx(name, prefix) == 0
				call add(matched, [name, text])
			endif
		endfor
		if a:sort
			call sort(matched)
		endif
		let output = []
		for [name, text] in matched
			let item = {'word':name, 'kind': a:kind, 'menu':text}
			call add(output, item)
		endfor
		return output
	endif
endfunc



