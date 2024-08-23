"======================================================================
"
" colorexp.vim - 
"
" Created by skywind on 2024/02/01
" Last Modified: 2024/02/01 16:37:38
"
"======================================================================


"----------------------------------------------------------------------
" error message
"----------------------------------------------------------------------
function! s:errmsg(text)
	echohl ErrorMsg
	echom a:text
	echohl None
endfunc


"----------------------------------------------------------------------
" strip text
"----------------------------------------------------------------------
function! s:StringStrip(text)
	return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunc


"----------------------------------------------------------------------
" command
"----------------------------------------------------------------------
command! -bang -nargs=1 -range=0 -complete=file ColorExport 
			\ call s:ColorExport(<bang>0, <q-args>)

function! s:ColorExport(bang, name)
	let name = expand(a:name)
	if name !~ '\.vim$'
		let name = name .. '.vim'
	endif
	if filereadable(name)
		if a:bang == 0
			call s:errmsg('File already exists, use :ColorExport! to overwrite')
			return 0
		endif
	endif
	let dirhome = fnamemodify(name, ':p:h')
	if !isdirectory(dirhome)
		call s:errmsg(printf('Directory does not exist: %s', dirhome))
		return 0
	endif
	let ts = reltime()
	call colorexp#export#proceed(name)
	let tt = reltime(ts)
	let time = reltimestr(tt)
	let time = s:StringStrip(time)
	echo printf('"%s" exported in %s seconds', name, time)
	return 1
endfunc


