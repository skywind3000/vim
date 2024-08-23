"======================================================================
"
" navigator.vim - 
"
" Created by skywind on 2023/06/27
" Last Modified: 2023/06/27 22:54:41
"
"======================================================================


"----------------------------------------------------------------------
" Navigator
"----------------------------------------------------------------------
command! -nargs=1 -range=0 -bang Navigator 
			\ call navigator#start(0, <bang>0, <q-args>, <line1>, <line2>, <count>)

command! -nargs=1 -range=0 -bang NavigatorVisual
			\ call navigator#start(1, <bang>0, <q-args>, <line1>, <line2>, <count>)


