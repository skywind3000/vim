"======================================================================
"
" variable.vim - 
"
" Created by skywind on 2024/05/10
" Last Modified: 2024/05/10 01:14:58
"
"======================================================================


"----------------------------------------------------------------------
" environment
"----------------------------------------------------------------------
let g:asynctasks_environ = get(g:, 'asynctasks_environ', {})


"----------------------------------------------------------------------
" variable get
"----------------------------------------------------------------------
function! module#variable#get(name, default) abort
	return get(g:asynctasks_environ, a:name, a:default)
endfunc


"----------------------------------------------------------------------
" variable set
"----------------------------------------------------------------------
function! module#variable#set(name, value) abort
	let g:asynctasks_environ[a:name] = a:value
endfunc


"----------------------------------------------------------------------
" append value
"----------------------------------------------------------------------
function! module#variable#append(name, value) abort
	let l:value = get(g:asynctasks_environ, a:name, '')
	let g:asynctasks_environ[a:name] = l:value . a:value
endfunc


"----------------------------------------------------------------------
" prepend value
"----------------------------------------------------------------------
function! module#variable#prepend(name, value) abort
	let l:value = get(g:asynctasks_environ, a:name, '')
	let g:asynctasks_environ[a:name] = a:value . l:value
endfunc



