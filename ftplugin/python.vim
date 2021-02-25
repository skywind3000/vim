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
	let s:pep8_rules = ['E101', 'E11', 'E121', 'E122', 'E123', 'E124', 'E125']
	let s:pep8_rules += ['E126', 'E127', 'E128', 'E129',  'E131', 'E133', ]
	let s:pep8_rules += ['E20', 'E211', 'E22', 'E224', 'E225', 'E226', 'E227']
	let s:pep8_rules += ['E228', 'E231', 'E241', 'E242', 'E251', 'E252']
	let s:pep8_rules += ['E27', 'E26', 'E265', 'E266', 'E', 'W']
endif


"----------------------------------------------------------------------
" initialize each python file
"----------------------------------------------------------------------
if s:has_autopep8
	setlocal formatprg=autopep8\ --select\ E,W\ -
elseif s:has_black
	setlocal formatprg=black\ -q\ -
elseif s:has_yapf
	setlocal formatprg=yapf
endif
	


