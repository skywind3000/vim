if exists('b:ftplugin_init_python')
	if get(b:, 'did_ftplugin', 0) == 2
		finish
	endif
endif

let b:ftplugin_init_python = 1

" prevent vim-plug set ft=? twice
if exists('b:did_ftplugin')
	let b:did_ftplugin = 2
endif

setlocal shiftwidth=4 
setlocal tabstop=4
setlocal expandtab

setlocal omnifunc=python3complete#Complete


"----------------------------------------------------------------------
" initialize once
"----------------------------------------------------------------------
if get(s:, 'once', 0) == 0
	let s:once = 1
	let s:has_black = executable('black')
	let s:has_autopep8 = executable('autopep8')
	let s:has_yapf = executable('yapf')
endif


"----------------------------------------------------------------------
" initialize each python file
"----------------------------------------------------------------------
if s:has_autopep8
	setlocal formatprg=autopep8\ -
elseif s:has_black
	setlocal formatprg=black\ -q\ -
elseif s:has_yapf
	setlocal formatprg=yapf
endif
	


