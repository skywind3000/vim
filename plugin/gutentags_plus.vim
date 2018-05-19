"======================================================================
"
" gutentags_plus.vim - connecting gtags_cscope db on demand
"
" Created by skywind on 2018/04/25
" Last Modified: 2018/05/19 21:48
"
"======================================================================

let s:windows = has('win32') || has('win64') || has('win16') || has('win95')

if v:version >= 800
	set cscopequickfix=s+,c+,d+,i+,t+,e+,g+,f+,a+
else
	set cscopequickfix=s+,c+,d+,i+,t+,e+,g+,f+
endif

let g:gutentags_auto_add_gtags_cscope = 0


"----------------------------------------------------------------------
" strip heading and ending spaces 
"----------------------------------------------------------------------
function! s:string_strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
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
	return records
endfunc

" noautocmd echo s:list_cscope_dbs()


"----------------------------------------------------------------------
" check db is connected
"----------------------------------------------------------------------
function! s:db_connected(dbname)
	let record = s:list_cscope_dbs()
	for item in record
		let p1 = fnamemodify(item.path, ':p')
		let p2 = fnamemodify(a:dbname, ':p')
		let equal = 0
		if s:windows || has('win32unix')
			let p1 = tolower(p1)
			let p2 = tolower(p2)
		endif
		if s:windows
			let p1 = tr(p1, "\\", "/")
			let p2 = tr(p2, "\\", "/")
		endif
		if p1 == p2
			return 1
		endif
	endfor
	return 0
endfunc


"----------------------------------------------------------------------
" add to cscope database if not connected
"----------------------------------------------------------------------
function! s:GscopeAdd() abort
	let dbname = s:get_gtags_file()
	let root = get(b:, 'gutentags_root', '')
	if dbname == '' || root == ''
		call s:ErrorMsg("no gtags database for this project, check gutentags's documents")
		return 0
	endif
	if !filereadable(dbname)
		call s:ErrorMsg('gtags database is not ready yet')
		return 0
	endif
	if s:db_connected(dbname)
		return 1
	endif
	let value = &cscopeverbose
	let $GTAGSDBPATH = fnamemodify(dbname, ':p:h')
	let $GTAGSROOT = root
	let prg = get(g:, 'gutentags_gtags_cscope_executable', 'gtags-cscope')
	execute 'set cscopeprg=' . fnameescape(prg)
	set nocscopeverbose
	silent exec 'cs kill -1'
	exec 'cs add '. fnameescape(dbname)
	if value != 0
		set cscopeverbose
	endif
	return 1
endfunc

command! -nargs=0 GscopeAdd call s:GscopeAdd()


"----------------------------------------------------------------------
" open quickfix
"----------------------------------------------------------------------
function! s:quickfix_open(size)
	function! s:WindowCheck(mode)
		if &buftype == 'quickfix'
			let s:quickfix_open = 1
			return
		endif
		if a:mode == 0
			let w:quickfix_save = winsaveview()
		else
			if exists('w:quickfix_save')
				call winrestview(w:quickfix_save)
				unlet w:quickfix_save
			endif
		endif
	endfunc
	let s:quickfix_open = 0
	let l:winnr = winnr()			
	noautocmd windo call s:WindowCheck(0)
	noautocmd silent! exec ''.l:winnr.'wincmd w'
	if s:quickfix_open != 0
		return
	endif
	exec 'botright copen '. ((a:size > 0)? a:size : '')
	noautocmd windo call s:WindowCheck(1)
	noautocmd silent! exec ''.l:winnr.'wincmd w'
endfunc


"----------------------------------------------------------------------
" Find search
"----------------------------------------------------------------------
function! s:GscopeFind(bang, what, ...)
	let keyword = (a:0 > 0)? a:1 : ''
	let dbname = s:get_gtags_file()
	let root = get(b:, 'gutentags_root', '')
	if dbname == '' || root == ''
		call s:ErrorMsg("no gtags database for this project, check gutentags's documents")
		return 0
	endif
	if !filereadable(dbname)
		call s:ErrorMsg('gtags database is not ready yet')
		return 0
	endif
	if a:0 == 0 || keyword == ''
		redraw! | echo '' | redraw!
		echohl ErrorMsg
		echom 'E560: Usage: GscopeFind a|c|d|e|f|g|i|s|t name'
		echohl NONE
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
	let text = "[cscope ".a:what.": ".text."]"
	let title = "GscopeFind ".a:what.' "'.keyword.'"'
	if has('nvim') == 0 && (v:version >= 800 || has('patch-7.4.2210'))
		call setqflist([], ' ', {'title':title})
	elseif has('nvim') && has('nvim-0.2.2')
		call setqflist([], ' ', {'title':title})
	elseif has('nvim')
		call setqflist([], ' ', title)
	else
		call setqflist([], ' ')
	endif
	call setqflist([{'text':text}], 'a')
	let success = 1
	try
		exec 'cs find '.a:what.' '.fnameescape(keyword)
		redrawstatus
	catch /^Vim\%((\a\+)\)\=:E259/
		redrawstatus
		echohl ErrorMsg
		echo "E259: not find '".keyword."'"
		echohl NONE
		let success = 0
	catch /^Vim\%((\a\+)\)\=:E567/
		redrawstatus
		echohl ErrorMsg
		echo "E567: no cscope connections"
		echohl NONE
		let success = 0
	catch /^Vim\%((\a\+)\)\=:E/
		redrawstatus
		echohl ErrorMsg
		echo "ERROR: cscope error"
		echohl NONE
		let success = 0
	endtry
	if winbufnr('%') == nbuf
		call cursor(nrow, ncol)
	endif
	if success != 0 && a:bang == 0
		let height = get(g:, 'gutentags_plus_height', 6)
		call s:quickfix_open(height)
	endif
endfunc


command! -nargs=+ -bang GscopeFind call s:GscopeFind(<bang>0, <f-args>)


"----------------------------------------------------------------------
" Kill all connections
"----------------------------------------------------------------------
function! s:GscopeKill()
	silent cs kill -1
	echo "All cscope connections have been closed."
endfunc

command! -nargs=0 GscopeKill call s:GscopeKill()



"----------------------------------------------------------------------
" setup keymaps
"----------------------------------------------------------------------
if get(g:, 'gutentags_plus_nomap', 0) == 0
	noremap <silent> <leader>cs :GscopeFind s <C-R><C-W><cr>
	noremap <silent> <leader>cg :GscopeFind g <C-R><C-W><cr>
	noremap <silent> <leader>cc :GscopeFind c <C-R><C-W><cr>
	noremap <silent> <leader>ct :GscopeFind t <C-R><C-W><cr>
	noremap <silent> <leader>ce :GscopeFind e <C-R><C-W><cr>
	noremap <silent> <leader>cf :GscopeFind f <C-R>=expand("<cfile>")<cr><cr>
	noremap <silent> <leader>ci :GscopeFind i <C-R>=expand("<cfile>")<cr><cr>
	noremap <silent> <leader>cd :GscopeFind d <C-R><C-W><cr>
	noremap <silent> <leader>ca :GscopeFind a <C-R><C-W><cr>
	noremap <silent> <leader>ck :GscopeKill<cr>
endif



