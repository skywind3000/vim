"======================================================================
"
" golang_mode.vim - 
"
" Created by skywind on 2024/04/01
" Last Modified: 2024/04/01 21:06:50
"
"======================================================================



"----------------------------------------------------------------------
" golang mode help
"----------------------------------------------------------------------
function! module#mode#golang_mode#help()
	return 'F1: run file, F2: go test, F3: go build, F4: go run'
endfunc



"----------------------------------------------------------------------
" init golang mode
"----------------------------------------------------------------------
function! module#mode#golang_mode#init()
	noremap <f1> :AsyncTask go-file-run<cr>
	noremap <f2> :AsyncTask go-project-test<cr>
	noremap <f3> :AsyncTask go-project-build<cr>
	noremap <f4> :AsyncTask go-project-run<cr>
endfunc


