"======================================================================
"
" git.vim - 
"
" Created by skywind on 2023/08/09
" Last Modified: 2023/08/09 16:04:27
"
"======================================================================


"----------------------------------------------------------------------
" get branch info
"----------------------------------------------------------------------
function! asclib#git#get_branch(where)
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return ''
	endif
	let hr = asclib#vcs#git('branch', root)
	for text in split(hr, '\n')
		let text = asclib#string#strip(text)
		let name = matchstr(text, '^\*\s*\zs\S\+\ze\s*$')
		let name = asclib#string#strip(name)
		if name != ''
			return name
		endif
	endfor
	return ''
endfunc


"----------------------------------------------------------------------
" get remote url
"----------------------------------------------------------------------
function! asclib#git#get_remote(where, name)
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return ''
	endif
	let hr = asclib#vcs#git('remote get-url ' . a:name, root)
	return (g:asclib#core#shell_error == 0)? asclib#string#strip(hr) : ''
endfunc


