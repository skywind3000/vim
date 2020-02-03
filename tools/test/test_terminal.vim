function! TermExit(code)
	echom "terminal exit code: ". a:code
endfunc

let opts = {'w':80, 'h':24, 'callback':'TermExit'}
call quickui#terminal#open('python', opts)


