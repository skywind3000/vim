
"----------------------------------------------------------------------
" detection
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win16') || has('win95') || has('win64')
let g:asclib#common#windows = s:windows
let g:asclib#common#unix = (s:windows == 0)? 1 : 0
let g:asclib#common#path = fnamemodify(expand('<sfile>:p'), ':h:h:h')


"----------------------------------------------------------------------
" error message
"----------------------------------------------------------------------
function! asclib#common#errmsg(text)
	redraw! | echo | redraw!
	echohl ErrorMsg
	echom a:text
	echohl None
endfunc


"----------------------------------------------------------------------
" write script
"----------------------------------------------------------------------
function! asclib#common#writefile(lines, name)
	if v:version >= 700
		call writefile(a:lines, a:name)
	else
		exe 'redir ! > '.fnameescape(a:name)
		for index in range(len(a:line))
			silent echo a:line[index]
		endfor
		redir END
	endif
endfunc


"----------------------------------------------------------------------
" class.word
"----------------------------------------------------------------------
function! asclib#common#class_word()
	let text = getline('.')
	let pre = text[:col('.') - 1]
	let suf = text[col('.'):]
	let word = matchstr(pre, "[A-Za-z0-9_.]*$") 
	let word = word . matchstr(suf, "^[A-Za-z0-9_]*")
	let cword = expand('<cword>')
	return (strlen(word) > strlen(cword))? word : cword
endfunc


