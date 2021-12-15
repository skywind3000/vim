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
function! s:require_check()
	if get(g:, 'quickui_version', '') == ''
		call s:errmsg('skywind3000/vim-quickui 1.4.3+ is required')
		return v:false
	endif
	let c1 = g:quickui#core#has_popup
	let c2 = g:quickui#core#has_floating
	if has('nvim') == 0
		if c1 == 0
			call s:errmsg('Vim 8.2 or above is required')
			return v:false
		endif
	elseif c2 == 0
		call s:errmsg('NeoVim 0.5.0 or above is required')
		return v:false
	endif
	return v:true
endfunc



"----------------------------------------------------------------------
" api input
"----------------------------------------------------------------------
function! s:api_input(msg, text, history)
	if s:require_check() == 0
		return ''
	endif
	return quickui#input#open(a:msg, a:text, a:history)
endfunc


"----------------------------------------------------------------------
" api confirm
"----------------------------------------------------------------------
function! s:api_confirm(msg, choices, index)
	if s:require_check() == 0
		return 0
	endif
	let index = (a:index == 0)? 1 : a:index
	return quickui#confirm#open(a:msg, a:choices, index)
endfunc


"----------------------------------------------------------------------
" init hook
"----------------------------------------------------------------------
function! g:asynctasks_api_hook.init()
	if get(g:, 'quickui_version', '') != ''
		let c1 = g:quickui#core#has_popup
		let c2 = g:quickui#core#has_floating
		if c1 || c2
			let g:asynctasks_api_hook.input = function('s:api_input')
			let g:asynctasks_api_hook.confirm = function('s:api_confirm')
		endif
	endif
endfunc


