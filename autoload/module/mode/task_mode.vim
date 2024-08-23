"======================================================================
"
" task_mode.vim - 
"
" Created by skywind on 2024/03/16
" Last Modified: 2024/03/16 19:26:38
"
"======================================================================


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#mode#task_mode#help()
	return 'F1-F4: task-f1, task-f2, task-f3, task-f4'
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#mode#task_mode#init()
	noremap <f1> :<c-u>AsyncTask task-f1<cr>
	noremap <f2> :<c-u>AsyncTask task-f2<cr>
	noremap <f3> :<c-u>AsyncTask task-f3<cr>
	noremap <f4> :<c-u>AsyncTask task-f4<cr>
	inoremap <f1> <esc>:AsyncTask task-f1<cr>
	inoremap <f2> <esc>:AsyncTask task-f2<cr>
	inoremap <f3> <esc>:AsyncTask task-f3<cr>
	inoremap <f4> <esc>:AsyncTask task-f4<cr>
endfunc



"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#mode#task_mode#quit()
endfunc


