"======================================================================
"
" runner_load.vim - 
"
" Created by skywind on 2021/12/15
" Last Modified: 2021/12/15 05:40:55
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let g:asyncrun_event = get(g:, 'asyncrun_event', {})
let g:asyncrun_runner = get(g:, 'asyncrun_runner', {})


"----------------------------------------------------------------------
" init runner
"----------------------------------------------------------------------
function! g:asyncrun_event.runner(name)
	let name = a:name
	if has_key(g:asyncrun_runner, name)
		return
	endif
	let test = 'asyncrun#runner#' . name . '#run'
	let load = 'autoload/asyncrun/runner/' . name . '.vim'
	silent exec 'runtime ' . fnameescape(load)
	if exists('*' . test)
		let g:asyncrun_runner[name] = test
	endif
endfunc



