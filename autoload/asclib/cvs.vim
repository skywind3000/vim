

"----------------------------------------------------------------------
" basic function
"----------------------------------------------------------------------
function! asclib#cvs#git(command, cwd)
	return asclib#core#system('git ' . a:command, a:cwd)
endfunc

function! asclib#cvs#svn(command, cwd)
	return asclib#core#system('svn ' . a:command, a:cwd)
endfunc

function! asclib#csv#root(where)
	let place = (a:where == '')? expand('%:p') : (a:where)
	return 
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! asclib#cvs#git_branch(where)
	let place = (a:where == '')? expand('%:p') : (a:where)
	if isdirectory(a:where) == 0
		let place = fnamemodify(a:where, ':p:h')
	endif
	let hr = asclib#csv#git(place
endfunc


