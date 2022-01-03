"======================================================================
"
" outlinear.vim - 
"
" Created by skywind on 2021/12/31
" Last Modified: 2021/12/31 03:56:22
"
"======================================================================


"----------------------------------------------------------------------
" global config
"----------------------------------------------------------------------
let g:maplocalleader = "\<c-\>"

let g:vo_modules_load = "checkbox:tags:smart_paste"
let g:vo_modules_load .= ':math'
let g:vo_modules_load .= ':newhoist'
let g:vo_modules_load .= ':format'
let g:vo_modules_load .= ':clock'


"----------------------------------------------------------------------
" change localleader
"----------------------------------------------------------------------
function! s:otl_init()
	" echo "hahaha"
endfunc


"----------------------------------------------------------------------
" auto command
"----------------------------------------------------------------------
augroup MyVimOutliner
	au! 
	au! BufRead,BufNewFile *.otl  call s:otl_init()
	au! BufRead,BufNewFile *.otn  call s:otl_init()
augroup END


