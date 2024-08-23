"======================================================================
"
" dosini.vim - 
"
" Created by skywind on 2023/08/03
" Last Modified: 2023/08/03 20:52:56
"
"======================================================================


"----------------------------------------------------------------------
" detect platform
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win16') || has('win64') || has('win95')


"----------------------------------------------------------------------
" integrity check
"----------------------------------------------------------------------
if exists(':AsyncTask') != 2 || exists(':AsyncRun') != 2
	" force lazy loader to load 
	silent! exec "AsyncRun -mode=load"
	silent! exec "AsyncTask -load"
	if exists(':AsyncTask') != 2 || exists(':AsyncRun') != 2
		runtime! plugin/asyncrun.vim
		runtime! plugin/asynctasks.vim
		if exists(':AsyncTask') != 2 || exists(':AsyncRun') != 2
			finish
		endif
	endif
endif


"----------------------------------------------------------------------
" extract names
"----------------------------------------------------------------------
function! s:config_names()
	let cname = get(g:, 'asynctasks_config_name', '.tasks')
	let parts = (type(cname) == 1)? split(cname, ',') : cname
	let names = []
	for name in parts
		let t = substitute(name, '^\s*\(.\{-}\)\s*$', '\1', '')
		if t != ''
			let names += [t]
		endif
	endfor
	return names
endfunc


"----------------------------------------------------------------------
" check task config
"----------------------------------------------------------------------
function! s:check_task_config()
	let rtp_config = get(g:, 'asynctasks_rtp_config', 'tasks.ini')
	let sname = expand('%:t')
	for cname in s:config_names()
		let cname = fnamemodify(cname, ':t')
		if sname == cname
			return 1
		endif
	endfor
	let filepath = expand('%:p')
	for dirname in split(&rtp, ',')
		let t = printf('%s/%s', dirname, rtp_config)
		if asyncrun#utils#path_equal(filepath, t) != 0
			" echom printf("test: '%s' '%s'", filepath, t)
			return 1
		endif
	endfor
	return 0
endfunc

if s:check_task_config() == 0
	finish
endif


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
setlocal omnifunc=comptask#omnifunc

if get(g:, 'asynctasks_complete', 0)
	let b:apm_omni = 1
	let b:apc_enable = 0
	setlocal cpt=.,b
	set shortmess+=c
	if exists(':ApcEnable')
		ApcDisable
	endif
	call comptask#complete_enable()
endif


