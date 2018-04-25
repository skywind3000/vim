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
	redir => cs_list
	noautocmd silent cs show
	redir END
	let records = []
	for text in split(cs_list, "\n")
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
	silent! redraw!
	return records
endfunc

" noautocmd echo s:list_cscope_dbs()


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
function! s:GscopeFind(bang, what, ...)
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
	if a:0 == 0
		if index(['i', '8', 'f', '7'], a:what) < 0
			let keyword = expand('<cword>')
		else
			let keyword = expand('<cfile>')
			if a:what == 'i' || a:what == '8'
				let keyword = '^'.keyword.'$'
			endif
		endif
	endif
	if keyword == ''
		call s:ErrorMsg('E560: Usage: GscopeFind a|c|d|e|f|g|i|s|t name')
		return 0
	endif
	call s:GscopeAdd()
	let ncol = col('.')
	let nrow = line('.')
	let nbuf = winbufnr('%')
	let text = ''
	if a:what == '0' || a:what == 's'
		let text = 'symbol "'.keyword.'"'
	elseif a:what == '1' || a:what == 'g'
		let text = 'definition of "'.keyword.'"'
	elseif a:what == '2' || a:what == 'd'
		let text = 'functions called by "'.keyword.'"'
	elseif a:what == '3' || a:what == 'c'
		let text = 'functions calling "'.keyword.'"'
	elseif a:what == '4' || a:what == 't'
		let text = 'string "'.keyword.'"'
	elseif a:what == '6' || a:what == 'e'
		let text = 'egrep "'.keyword.'"'
	elseif a:what == '7' || a:what == 'f'
		let text = 'file "'.keyword.'"'
	elseif a:what == '8' || a:what == 'i'
		let text = 'files including "'.keyword.'"'
	elseif a:what == '9' || a:what == 'a'
		let text = 'assigned "'.keyword.'"'
	endif
	silent cexpr "[cscope ".a:what.": ".l:text."]"
	let success = 1
	try
		exec 'cs find '.a:what.' '.fnameescape(keyword)
	catch /^Vim\%((\a\+)\)\=:E259/
		echohl ErrorMsg
		echo "E259: not find '".keyword."'"
		echohl NONE
		let success = 0
	catch /^Vim\%((\a\+)\)\=:E567/
		echohl ErrorMsg
		echo "E567: no cscope connections"
		echohl NONE
		let success = 0
	catch /^Vim\%((\a\+)\)\=:E/
		echohl ErrorMsg
		echo "ERROR: cscope error"
		echohl NONE
		let success = 0
	endtry
	if winbufnr('%') == nbuf
		call cursor(nrow, ncol)
	endif
	if success != 0 && a:bang != '!'
		if has('autocmd')
			doautocmd User VimScope
		endif
	endif
endfunc


command! -nargs=+ -bang GscopeFind call s:GscopeFind(<bang>0, <f-args>)


