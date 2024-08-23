if exists('b:ftplugin_init_go')
	if get(b:, 'did_ftplugin', 0) == 2
		finish
	endif
endif

let b:ftplugin_init_go = 1

" prevent vim-plug set ft=? twice
if exists('b:did_ftplugin')
	let b:did_ftplugin = 2
endif

let b:cursorword = 1


"----------------------------------------------------------------------
" once initializer
"----------------------------------------------------------------------
if get(s:, 'once', 0) == 0
	let s:once = 1
	let s:has_go = executable('go')
	let s:has_gofmt = executable('gofmt')
	let s:has_goimports = executable('goimports')
endif

if s:has_goimports
	setlocal formatprg=goimports
elseif s:has_gofmt
	setlocal formatprg=gofmt
endif


" install BufWritePre hook
call module#go#init()

let obj = asclib#core#object('b')
let obj.post_format = 0

if get(g:, 'module_go_post_format', 0)
	let obj.post_format = 1
endif

if get(g:, 'module_go_update_time', 1)
	let obj.update_time = 1
endif


"----------------------------------------------------------------------
" go run file
"----------------------------------------------------------------------
nnoremap <buffer> <F11> :AsyncTask go-run-file<cr>


"----------------------------------------------------------------------
" menu
"----------------------------------------------------------------------
let b:navigator = {}

let b:navigator.l = {
			\ 'b': [':AsyncTask go-project-build', 'go-project-build'],
			\ 't': [':AsyncTask go-project-test', 'go-project-test'],
			\ 'T': [':AsyncTask go-project-test-verbose', 'go-project-test-verbose'],
			\ 'i': [':AsyncTask go-project-install', 'go-project-install'],
			\ 'r': [':AsyncTask go-project-run', 'go-project-run'],
			\ }


