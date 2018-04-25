"======================================================================
"
" gutentags_plus.vim - config gtags
"
" Created by skywind on 2018/04/25
" Last Modified: 2018/04/25 15:40:46
"
"======================================================================

let s:windows = has('win32') || has('win64') || has('win16') || has('win95')


"----------------------------------------------------------------------
" strip heading and ending spaces 
"----------------------------------------------------------------------
function! s:string_strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunc


"----------------------------------------------------------------------
" compare two path names 
"----------------------------------------------------------------------
function! s:path_equal(path1, path2)
	let p1 = fnamemodify(a:path1, ':p')
	let p2 = fnamemodify(a:path2, ':p')
	if s:windows || has('win32unix')
		let p1 = tolower(p1)
		let p2 = tolower(p2)
	endif
	if p1 == p2
		return 1
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" display error message
"----------------------------------------------------------------------
function! s:ErrorMsg(msg)
	redraw! | echo "" | redraw!
	echohl ErrorMsg
	echom 'ERROR: '. a:msg
	echohl NONE
endfunc


"----------------------------------------------------------------------
" search gtags db by gutentags buffer variable
"----------------------------------------------------------------------
function! s:get_gtags_file() abort
	if !exists('b:gutentags_files')
		return ''
	endif
	if !has_key(b:gutentags_files, 'gtags_cscope')
		return ''
	endif
	let tags = b:gutentags_files['gtags_cscope']
	if filereadable(tags)
		return tags
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" list cscope dbs
"----------------------------------------------------------------------
function! s:list_cscope_dbs()
	redir => x
	silent! cs show
	redir END
	let records = []
	for text in split(x, "\n")
		let text = s:string_strip(text)
		if text == ''
			continue
		endif
		if strpart(text, 0, 1) == '#'
			continue
		endif
		let p1 = stridx(text, ' ')
		if p1 < 0
			continue
		endif
		let p2 = stridx(text, ' ', p1 + 1)
		if p2 < 0
			continue
		endif
		let p3 = strridx(text, ' ', len(text) - 1)
		if p3 < 0 || p3 <= p2
			continue
		endif
		let db_id = strpart(text, 0, p1)
		let db_pid = strpart(text, p1 + 1, p2 - p1)
		let db_path = strpart(text, p2 + 1, p3 - p2)
		let item = {}
		let item.id = s:string_strip(db_id)
		let item.pid = s:string_strip(db_pid)
		let item.path = s:string_strip(db_path)
		let records += [item]
	endfor
	return records
endfunc


"----------------------------------------------------------------------
" check db is connected
"----------------------------------------------------------------------
function! s:db_connected(dbname)
	let record = s:list_cscope_dbs()
	for item in record
		if s:path_equal(item.path, a:dbname)
			return 1
		endif
	endfor
	return 0
endfunc


"----------------------------------------------------------------------
" add to cscope database if not connected
"----------------------------------------------------------------------
function! s:GscopeAdd()
	let dbname = s:get_gtags_file()
	if dbname == ''
		return 0
	endif
	if s:db_connected(dbname)
		return 1
	endif
	let value = &cscopeverbose
	set nocscopeverbose
	exec 'cs add '. fnameescape(dbname)
	if value != 0
		set cscopeverbose
	endif
	return 1
endfunc

command! -nargs=0 GscopeAdd call s:GscopeAdd()


"----------------------------------------------------------------------
" Find search
"----------------------------------------------------------------------
function! s:GscopeFind(bang, query, ...)
	let keyword = (a:0 > 0)? a:1 : ''
	let dbname = s:get_gtags_file()
	if dbname == ''
		call s:ErrorMsg("no gtags database for this file, setup gutentags")
		return 0
	endif
	if !filereadable(dbname)
		call s:ErrorMsg('not find gtags database for this file')
		return 0
	endif
	call s:GscopeAdd(dbname)
endfunc


