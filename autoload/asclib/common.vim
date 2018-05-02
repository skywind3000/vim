
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
" python detection 
"----------------------------------------------------------------------
if !exists('g:asclib#common#py_version')
	let g:asclib#common#py_version = 0
endif


