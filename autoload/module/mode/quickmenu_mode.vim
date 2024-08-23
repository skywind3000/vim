"======================================================================
"
" quickmenu_mode.vim - 
"
" Created by skywind on 2024/03/16
" Last Modified: 2024/03/16 19:29:54
"
"======================================================================


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#mode#quickmenu_mode#help()
	return "S-F10: menu 0, C-F10: menu 1, C-F11: menu 2"
endfunc




"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#mode#quickmenu_mode#init()
	noremap <silent><S-F10> :call quickmenu#toggle(0)<cr>
	inoremap <silent><S-F10> <ESC>:call quickmenu#toggle(0)<cr>
	noremap <silent><c-f10> :call quickmenu#toggle(1)<cr>
	inoremap <silent><c-f10> <ESC>:call quickmenu#toggle(1)<cr>
	noremap <silent><c-f11> :call quickmenu#toggle(2)<cr>
	inoremap <silent><c-f11> <ESC>:call quickmenu#toggle(2)<cr>
endfunc



