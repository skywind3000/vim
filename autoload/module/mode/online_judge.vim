"----------------------------------------------------------------------
" golang mode help
"----------------------------------------------------------------------
function! module#mode#online_judge#help()
	return 'F1: run file, F2: run arg, F3: code check, F4: code debug'
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! s:run_file(mode)
	let opts = {}
	let opts.cwd = '$(VIM_FILEDIR)'
	let opts.mode = 'terminal'
	let opts.pos = 'external'
	let opts.save = 1
	if has('win32') || has('win64') || has('win95') || has('win16')
		let cmd = 'python C:\share\vim\lib\codecheck.py'
	else
		let cmd = 'python3 ~/.vim/vim/lib/codecheck.py'
	endif
	let mode = a:mode
	let cmd = cmd . ' ' . mode . ' "$(VIM_FILENAME)"'
	call asyncrun#run('', opts, cmd)
endfunc


"----------------------------------------------------------------------
" init golang mode
"----------------------------------------------------------------------
function! module#mode#online_judge#init()
	noremap <f1> :call <SID>run_file('')<cr>
	noremap <f2> :call <SID>run_file('-a')<cr>
	noremap <f3> :call <SID>run_file('-c')<cr>
	noremap <f4> :call <SID>run_file('-d')<cr>
endfunc



