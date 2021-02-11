

"----------------------------------------------------------------------
" basic function
"----------------------------------------------------------------------
function! asclib#cvs#git(command, cwd)
	return asclib#core#system('git ' . a:command, a:cwd)
endfunc

function! asclib#cvs#svn(command, cwd)
	return asclib#core#system('svn ' . a:command, a:cwd)
endfunc

function! asclib#cvs#root(where)
	let place = (a:where == '')? expand('%:p') : (a:where)
	let marker = ['.git', '.svn']
	return asclib#path#get_root(place, marker, 1)
endfunc


"----------------------------------------------------------------------
" git sub function
"----------------------------------------------------------------------
function! asclib#cvs#git_branch(where)
	let root = asclib#cvs#root(a:where)
	if root == ''
		return ''
	endif
	let hr = asclib#cvs#git('branch', root)
	if g:asclib#core#shell_error == 0
		let hr = asclib#string#strip(hr)
		let name = matchstr(hr, '^\*\s*\zs\S\+\ze\s*$')
		return asclib#string#strip(name)
	endif
	return ''
endfunc

function! asclib#cvs#git_remote(where, name)
	let root = asclib#cvs#root(a:where)
	if root == ''
		return ''
	endif
	let hr = asclib#cvs#git('remote get-url ' . a:name, root)
	return (g:asclib#core#shell_error == 0)? asclib#string#strip(hr) : ''
endfunc

function! asclib#cvs#git_fullname(name)
	let name = (a:name == '')? expand('%:p') : (a:name)
	let root = asclib#cvs#root(name)
	if root == ''
		return ''
	endif
	let hr = asclib#cvs#git('ls-files --full-name ' . shellescape(name), root)
	return (g:asclib#core#shell_error == 0)? asclib#string#strip(hr) : ''
endfunc

