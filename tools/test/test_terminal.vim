function! TermExit(code)
	echom "terminal exit code: ". a:code
endfunc

let opts = {'callback':'TermExit'}
call quickui#terminal#open('python', opts)


