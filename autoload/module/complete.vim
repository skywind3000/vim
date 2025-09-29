"======================================================================
"
" complete.vim - 
"
" Created by skywind on 2025/09/29
" Last Modified: 2025/09/29 14:54:56
"
"======================================================================


"----------------------------------------------------------------------
" check back space
"----------------------------------------------------------------------
function! module#complete#check_back_space() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1]  =~# '\s'
endfunc


"----------------------------------------------------------------------
" get text before cursor
"----------------------------------------------------------------------
function! module#complete#get_context() abort
	return strpart(getline('.'), 0, col('.') - 1)
endfunc


"----------------------------------------------------------------------
" get keyword from context
"----------------------------------------------------------------------
function! module#complete#meets_keyword(context) abort
	return matchstr(a:context, '\k\+$')
endfunc


"----------------------------------------------------------------------
" get current keyword before cursor
"----------------------------------------------------------------------
function! module#complete#current_keyword() abort
	let context = module#complete#get_context()
	return module#complete#meets_keyword(context)
endfunc



