"======================================================================
"
" win32.vim - 
"
" Created by skywind on 2024/03/21
" Last Modified: 2024/03/21 03:47:19
"
"======================================================================


"----------------------------------------------------------------------
" errmsg
"----------------------------------------------------------------------
function! s:errmsg(...) abort
	call asclib#common#errmsg(call('printf', a:000))
endfunc


"----------------------------------------------------------------------
" open .hlp file
"----------------------------------------------------------------------
function! asclib#win32#open_hlp(hlp, keyword) abort
	if !filereadable(a:hlp)
		call s:errmsg('can not open: %s', a:hlp)
		return 1
	endif
	if asclib#path#which('winhlp32.exe') == ''
		call s:errmsg('can not find WinHlp32.exe, please install it')
		return 2
	endif
	if executable('python')
		let path = asclib#path#runtime('lib/vimhelp.py')
		let cmd = 'python ' . shellescape(path) . ' -h '
		let cmd = cmd . shellescape(a:hlp)
		if a:keyword != ''
			let cmd .= ' ' . shellescape(a:keyword)
		endif
		exec 'AsyncRun -mode=5 '.cmd
		return 0
	endif
	let cmd = 'WinHlp32.exe '
	if a:keyword != ''
		let kw = split(a:keyword, ' ')[0]
		if kw != ''
			let cmd .= '-k '.kw. ' '
		endif
	endif
	call asclib#core#start(cmd . shellescape(a:hlp))
	return 0
endfunc


"----------------------------------------------------------------------
" open .chm file 
"----------------------------------------------------------------------
function! asclib#win32#open_chm(chm, keyword) abort
	if !filereadable(a:chm)
		call s:errmsg('can not open: %s', a:chm)
		return 1
	endif
	if a:keyword == ''
		silent exec 'AsyncRun -mode=5 '.shellescape(a:chm)
		return 0
	else
		if asclib#path#which('KeyHH.exe') == ''
			call s:errmsg('can not find KeyHH.exe, please install it')
			return 2
		endif
	endif
	let chm = shellescape(a:chm)
	let cmd = 'KeyHH.exe -\#klink '.shellescape(a:keyword).' '.chm
	call asclib#core#start(cmd)
endfunc



