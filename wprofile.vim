
function! ProfileInit(filename)
	exec 'profile start ' . fnameescape(a:filename)
	profile func *
	profile file *
endfunc


function! ProfileStop()
	silent! profdel func *
	silent! profdel file *
endfunc


function! MonitorInit()
	let ts = strftime("pf-%Y%m%d%H%M%S.txt")
	let name = expand('~/.vim/profile/' . ts)
	silent! call mkdir(expand('~/.vim/profile'), "p", 0755)
	silent! call ProfileStop()
	call ProfileInit(name)
	if 0
		profile pause
		function! <SID>PressF5()
			profile continue
			VimExecute run
			profile pause
		endfunc
		function! <SID>PressF9()
			profile continue
			VimBuild gcc
			profile pause
		endfunc
		noremap <silent><F5> :call <SID>PressF5()<cr>
		noremap <silent><F9> :call <SID>PressF9()<cr>
	endif
endfunc


function! MonitorExit()
	call ProfileStop()
	if 0
		noremap <silent><F5> :VimExecute run<cr>
		noremap <silent><F9> :VimBuild gcc<cr>
	endif
endfunc


