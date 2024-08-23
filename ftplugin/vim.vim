if &modifiable
	set ff=unix
endif

let b:cursorword = 1


"----------------------------------------------------------------------
" mapping
"----------------------------------------------------------------------
noremap <buffer><F11> :<c-u>silent update<cr>:so %<cr>


"----------------------------------------------------------------------
" navigator
"----------------------------------------------------------------------
let b:navigator_insert = {}
let b:navigator_insert.i = {
			\ 'i': [':CodeSnipExpand windows', 'windows-checker'],
			\ 's': [':CodeSnipExpand scripthome', 'script-home-detector'],
			\ 't': [':CodeSnipExpand try', 'insert-try-catch'],
			\ 'w': [':CodeSnipExpand while', 'insert-while-endwhile'],
			\ }

	
