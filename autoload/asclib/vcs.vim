

"----------------------------------------------------------------------
" basic function
"----------------------------------------------------------------------
function! asclib#vsc#git(command, cwd)
	return asclib#core#system('git ' . a:command, a:cwd)
endfunc

function! asclib#vsc#svn(command, cwd)
	return asclib#core#system('svn ' . a:command, a:cwd)
endfunc

function! asclib#vsc#root(where)
	let place = (a:where == '')? expand('%:p') : (a:where)
	let marker = ['.git', '.svn']
	return asclib#path#get_root(place, marker, 1)
endfunc


"----------------------------------------------------------------------
" git sub function
"----------------------------------------------------------------------
function! asclib#vsc#git_branch(where)
	let root = asclib#vsc#root(a:where)
	if root == ''
		return ''
	endif
	let hr = asclib#vsc#git('branch', root)
	if g:asclib#core#shell_error == 0
		let hr = asclib#string#strip(hr)
		let name = matchstr(hr, '^\*\s*\zs\S\+\ze\s*$')
		return asclib#string#strip(name)
	endif
	return ''
endfunc

function! asclib#vsc#git_remote(where, name)
	let root = asclib#vsc#root(a:where)
	if root == ''
		return ''
	endif
	let hr = asclib#vsc#git('remote get-url ' . a:name, root)
	return (g:asclib#core#shell_error == 0)? asclib#string#strip(hr) : ''
endfunc

function! asclib#vsc#git_fullname(name)
	let name = (a:name == '')? expand('%:p') : (a:name)
	let root = asclib#vsc#root(name)
	if root == ''
		return ''
	endif
	let hr = asclib#vsc#git('ls-files --full-name ' . shellescape(name), root)
	return (g:asclib#core#shell_error == 0)? asclib#string#strip(hr) : ''
endfunc

