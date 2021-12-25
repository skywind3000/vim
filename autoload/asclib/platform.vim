"======================================================================
"
" platform.vim - 
"
" Created by skywind on 2021/12/26
" Last Modified: 2021/12/26 02:29:06
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :

"----------------------------------------------------------------------
" system detection 
"----------------------------------------------------------------------
if has('win32') || has('win64') || has('win95') || has('win16')
	let s:uname = 'windows'
elseif has('win32unix')
	let s:uname = 'cygwin'
elseif has('linux') || has('wsl')
	let s:uname = 'linux'
elseif has('unix') && (has('mac') || has('macunix') || has('macvim'))
	let s:uname = 'darwin'
elseif has('bsd')
	let s:uname = 'bsd'
elseif has('unix')
	let s:uname = substitute(system("uname"), '\s*\n$', '', 'g')
	if v:shell_error == 0 && match(s:uname, 'Linux') >= 0
		let s:uname = 'linux'
	elseif v:shell_error == 0 && match(s:uname, 'FreeBSD') >= 0
		let s:uname = 'bsd'
	elseif v:shell_error == 0 && match(s:uname, 'Darwin') >= 0
		let s:uname = 'darwin'
	else
		let s:uname = 'posix'
	endif
else
	let s:uname = 'posix'
endif


"----------------------------------------------------------------------
" ostype
"----------------------------------------------------------------------
function! asclib#platform#uname()
	return s:uname
endfunc



