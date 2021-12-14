"======================================================================
"
" task_extension.vim - 
"
" Created by skywind on 2021/12/14
" Last Modified: 2021/12/14 17:19:47
"
"======================================================================


"----------------------------------------------------------------------
" api hook
"----------------------------------------------------------------------
let g:asynctasks_api_hook = get(g:, 'asynctasks_api_hook', {})


"----------------------------------------------------------------------
" utils
"----------------------------------------------------------------------
function! s:errmsg(msg)
	redraw
	echohl ErrorMsg
	echom 'ERROR: ' . a:msg
	echohl NONE
	return 0
endfunction


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! s:require_quickui()
	if get(g:, 'quickui_version', '') == ''
		call s:errmsg('skywind3000/vim-quickui 1.4.3+ is required')
		return v:false
	endif
	let c1 = g:quickui#core#has_popup
	let c2 = g:quickui#core#has_floating
	if c1 || c2
		return v:true
	endif
	return v:true
endfunc



"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! s:api_input(msg, text, history)
endfunc


