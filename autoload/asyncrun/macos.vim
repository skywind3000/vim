"======================================================================
"
" macos.vim - 
"
" Created by skywind on 2021/12/30
" Last Modified: 2021/12/30 15:52:58
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :


"----------------------------------------------------------------------
" script name
"----------------------------------------------------------------------
function! macos#script_name(name)
	let tmpname = fnamemodify(tempname(), ':h') . '/' . a:name
	return tmpname
endfunc


"----------------------------------------------------------------------
" return pause script
"----------------------------------------------------------------------
function! macos#pause_script()
	let lines = []
	if executable('bash')
		let pause = 'read -n1 -rsp "press any key to continue ..."'
		let lines += ['bash -c ''' . pause . '''']
	else
		let lines += ['echo "press enter to continue ..."']
		let lines += ['sh -c "read _tmp_"']
	endif
	return lines
endfunc


"----------------------------------------------------------------------
" open system terminal
"----------------------------------------------------------------------
function! macos#open_system(title, script, profile)
	let content = ['#! /bin/sh']
	let content = ['clear']
	let content += a:script
	let tmpname = macos#script_name('runner1.sh')
	call writefile(content, tmpname)
	silent! call setfperm(tmpname, 'rwxrwxrws')
	let cmd = 'open -a Terminal ' . shellescape(tmpname)
	call system(cmd . ' &')
endfunc


