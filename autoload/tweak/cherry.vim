"======================================================================
"
" cherry.vim - 
"
" Created by skywind on 2021/02/01
" Last Modified: 2021/02/01 23:33:23
"
"======================================================================


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
let s:py_cmd = g:asclib#python#py_cmd
let s:py_eval = g:asclib#python#py_eval
let s:py_ver = g:asclib#python#py_ver

let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h')

call asclib#python#path_add(s:scripthome)
call asclib#python#reload('cherry')

exec s:py_cmd "import cherry"


