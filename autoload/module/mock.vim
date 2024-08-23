"======================================================================
"
" mockcmd.vim - 
"
" Created by skywind on 2023/06/22
" Last Modified: 2023/06/22 00:55:12
"
"======================================================================


"----------------------------------------------------------------------
" mock command
"----------------------------------------------------------------------
function! s:mockcmd(cmdname, bang, line1, line2, args, init) abort
	if exists(':' . a:cmdname) == 2
		exec 'delcommand ' . a:cmdname
	endif
	if type(a:init) == type('')
		exec a:init
	elseif type(a:init) == type([])
		exec join(a:init, "\n")
	endif
	let t = printf("%d,%d", a:line1, a:line2)
	let t = printf("%s%s%s", (a:line1 == a:line2)? '' : t, a:cmdname, a:bang)
	exec t . ' ' . a:args
endfunc


"----------------------------------------------------------------------
" make mock command
"----------------------------------------------------------------------
function! s:make(cmdname, complete, init) abort
	if !exists('s:init')
		let s:init = []
	endif
	let n = len(s:init)
	let s:init += [deepcopy(a:init)]
	let t = 'command! -nargs=* -range -bang '
	let t .= (a:complete == '')? '-complete=file' : '-complete='. a:complete
	let t .= ' ' . a:cmdname . ' call s:mockcmd('
	let t .= printf('"%s", "<bang>", <line1>, <line2>, <q-args>, ', a:cmdname)
	let t .= printf('s:init[%d])', n)
	exec t
endfunc


"----------------------------------------------------------------------
" mock command and init by script
"----------------------------------------------------------------------
function! module#mock#command(cmdname, complete, init) abort
	return s:make(a:cmdname, a:complete, a:init)
endfunc


"----------------------------------------------------------------------
" init command by opt
"----------------------------------------------------------------------
function! module#mock#init_optname(cmdname, complete, optname) abort
	let load = []
	let init = []
	if type(a:optname) == type('')
		let load = [a:optname]
	elseif type(a:optname) == type([])
		let load = a:optname
	endif
	let b = asclib#path#runtime('site/opt')
	for name in load
		let t = asclib#path#join(b, name)
		let cmd = 'source ' . fnameescape(t)
		let init += [cmd]
	endfor
	return module#mock#command(a:cmdname, a:complete, init)
endfunc


"----------------------------------------------------------------------
" init packad
"----------------------------------------------------------------------
function! module#mock#init_packadd(cmdname, complete, packname) abort
	let load = []
	let init = []
	if type(a:packname) == type('')
		let load = [a:packname]
	elseif type(a:packname) == type([])
		let load = a:packname
	endif
	for name in load
		let t = 'packadd ' . fnameescape(name)
		let init += [t]
	endfor
	return module#mock#command(a:cmdname, a:complete, init)
endfunc



