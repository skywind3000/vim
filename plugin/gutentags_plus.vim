"======================================================================
"
" gutentags_plus.vim - connecting gtags_cscope db on demand
"
" Created by skywind on 2018/04/25
" Last Modified: 2021/03/02 23:30
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :

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
	let pwd = getcwd()
	let s:previous_pwd = get(s:, 'previous_pwd', '')
	if s:db_connected(dbname)
		if s:previous_pwd == pwd
			return 1
		endif
	endif
	let s:previous_pwd = pwd
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
			let s:quickfix_wid = winnr()
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
		if get(g:, 'gutentags_plus_switch', 0) != 0
			noautocmd silent! exec ''.s:quickfix_wid.'wincmd w'
		endif
		return
	endif
	exec 'botright copen '. ((a:size > 0)? a:size : '')
	noautocmd windo call s:WindowCheck(1)
	noautocmd silent! exec ''.l:winnr.'wincmd w'
	if get(g:, 'gutentags_plus_switch', 0) != 0
		noautocmd silent! exec ''.s:quickfix_wid.'wincmd w'
	endif
endfunc


"----------------------------------------------------------------------
" Find search
"----------------------------------------------------------------------
function! s:GscopeFind(bang, what, ...)
	let keyword = (a:0 > 0)? a:1 : ''
	let dbname = s:get_gtags_file()
	let root = get(b:, 'gutentags_root', '')
	if (dbname == '' || root == '') && a:what != 'z'
		call s:ErrorMsg("no gtags database for this project, check gutentags's documents")
		return 0
	endif
	if a:0 == 0 || keyword == ''
		redraw! | echo '' | redraw!
		echohl ErrorMsg
		echom 'E560: Usage: GscopeFind a|c|d|e|f|g|i|s|t|z name'
		echohl NONE
		return 0
	endif
	if a:what == 'z'
		let ft = (a:0 > 1)? a:2 : (&ft)
		return s:FindTags(a:bang, keyword, ft)
	endif
	if !filereadable(dbname)
		call s:ErrorMsg('gtags database is not ready yet')
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
	let save_local = &l:efm
	let save_global = &g:efm
	let &g:efm = '%f:%l:%m'
	let &l:efm = '%f:%l:%m'
	silent exec 'cexpr text'
	if has('nvim') == 0 && (v:version >= 800 || has('patch-7.4.2210'))
		call setqflist([], 'a', {'title':title})
	elseif has('nvim') && has('nvim-0.2.2')
		call setqflist([], 'a', {'title':title})
	elseif has('nvim')
		call setqflist([], 'a', title)
	else
		call setqflist([], 'a')
	endif
	" call setqflist([{'text':text}], 'a')
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
	let &g:efm = save_global
	let &l:efm = save_local
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
" taglist
"----------------------------------------------------------------------
function! s:global_taglist(pattern) abort
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
	let pwd = getcwd()
	let $GTAGSDBPATH = fnamemodify(dbname, ':p:h')
	let $GTAGSROOT = root
	let lst = systemlist('global --result=cscope -a "'. a:pattern . '"')
	let rsl_list = []
	for li in lst
		let tag_info = {}
		let tag_info['filename'] = li[:stridx(li, " ") - 1]
		let li = li[stridx(li, " ") + 1:]
		let tag_info['name'] = li[:stridx(li, " ") - 1]
		let li = li[stridx(li, " ") + 1:]
		let tag_info['line'] = str2nr(li[:stridx(li, " ") - 1])
		let li = li[stridx(li, " ") + 1:]
		let tag_info['cmd'] = '/^' . li . '$/'
		let rsl_list = add(rsl_list, tag_info)
	endfor
	return rsl_list
endfunc


function! s:taglist(pattern)
	let ftags = []
	try
		if &cscopetag
			let ftags = s:global_taglist(a:pattern)
		else
			let ftags = taglist(a:pattern)
		endif
	catch /^Vim\%((\a\+)\)\=:E/
		" if error occured, reset tagbsearch option and try again.
		let bak = &tagbsearch
		set notagbsearch
		if &cscopetag
			let ftags = s:global_taglist(a:pattern)
		else
			let ftags = taglist(a:pattern)
		endif
		let &tagbsearch = bak
	endtry
	" take care ctags windows filename bug
	let win = has('win32') || has('win64') || has('win95') || has('win16')
	for item in ftags
		let name = get(item, 'filename', '')
		let item.baditem = 0
		if win != 0
			if stridx(name, '\\') >= 0
				let part = split(name, '\\', 1)
				let elem = []
				for n in part
					if n != ''
						let elem += [n]
					endif
				endfor
				let name = join(elem, '\')
				let item.filename = name
				if has_key(item, 'line') == 0
					if has_key(item, 'signature') == 0
						let kind = get(item, 'kind', '')
						if kind != 'p' && kind != 'f'
							let item.baditem = 1
						endif
					endif
				endif
			end
		endif
	endfor
	return ftags
endfunc


"----------------------------------------------------------------------
" easy tagname
"----------------------------------------------------------------------
function! s:tagfind(tagname)
	let pattern = escape(a:tagname, '[\*~^')
	let result = s:taglist("^". pattern . "$")
	if type(result) == 0 || (type(result) == 3 && result == [])
		if pattern !~ '^\(catch\|if\|for\|while\|switch\)$'
			let result = s:taglist('::'. pattern .'$')
		endif
	endif
	if type(result) == 0 || (type(result) == 3 && result == [])
		return []
	endif
	let final = []
	let check = {}
	for item in result
		if item.baditem != 0
			continue
		endif
		" remove duplicated tags
		let signature = get(item, 'name', '') . ':'
		let signature .= get(item, 'cmd', '') . ':'
		let signature .= get(item, 'kind', '') . ':'
		let signature .= get(item, 'line', '') . ':'
		let signature .= get(item, 'filename', '')
		if !has_key(check, signature)
			let final += [item]
			let check[signature] = 1
		endif
	endfor
	return final
endfunc


"----------------------------------------------------------------------
" function signature
"----------------------------------------------------------------------
function! s:signature(funname, fn_only, filetype)
	let tags = s:tagfind(a:funname)
	let funpat = escape(a:funname, '[\*~^')
	let fill_tag = []
	let ft = (a:filetype == '')? &filetype : a:filetype
	for i in tags
		if !has_key(i, 'name')
			continue
		endif
		if has_key(i, 'language')
		endif
		if has_key(i, 'filename') && ft != '*'
			let ename = tolower(fnamemodify(i.filename, ':e'))
			let c = ['c', 'cpp', 'cc', 'cxx', 'h', 'hpp', 'hh', 'm', 'mm']
			if index(['c', 'cpp', 'objc', 'objcpp'], ft) >= 0
				if index(c, ename) < 0
					continue
				endif
			elseif ft == 'python'
				if index(['py', 'pyw'], ename) < 0
					continue
				endif
			elseif ft == 'java' && ename != 'java'
				continue
			elseif ft == 'ruby' && ename != 'rb'
				continue
			elseif ft == 'vim' && ename != 'vim'
				continue
			elseif ft == 'cs' && ename != 'cs'
				continue
			elseif ft == 'php' 
				if index(['php', 'php4', 'php5', 'php6'], ename) < 0
					continue
				endif
			elseif ft == 'javascript'
				if index(['html', 'js', 'html5', 'xhtml', 'php'], ename) < 0
					continue
				endif
			endif
		endif
		if has_key(i, 'kind')
			" p: prototype/procedure; f: function; m: member
			if (a:fn_only == 0 || (i.kind == 'p' || i.kind == 'f') ||
						\ (i.kind == 'm' && has_key(i, 'cmd') &&
						\		match(i.cmd, '(') != -1)) &&
						\ i.name =~ funpat
				if ft != 'cpp' || !has_key(i, 'class') ||
							\ i.name !~ '::' || i.name =~ i.class
					let fill_tag += [i]
				endif
			endif
		else
			if a:fn_only == 0 && i.name == a:funname
				let fill_tag += [i]
			endif
		endif
	endfor
	let res = []
	let check = {}
	for i in fill_tag
		if has_key(i, 'kind') && has_key(i, 'signature')
			if i.cmd[:1] == '/^' && i.cmd[-2:] == '$/'
				let tmppat = substitute(escape(i.name,'[\*~^'),
							\ '^.*::','','')
				if ft == 'cpp'
					let tmppat = substitute(tmppat,'\<operator ',
								\ 'operator\\s*','')
					let tmppat=tmppat . '\s*(.*'
					let tmppat='\([A-Za-z_][A-Za-z_0-9]*::\)*'.tmppat
				else
					let tmppat=tmppat . '\>.*'
				endif
				let name = substitute(i.cmd[2:-3],tmppat,'','').
							\ i.name . i.signature
				if i.kind == 'm'
					if has_key(i, 'class')
						let name = name . ' <-- class ' . i.class
					elseif has_key(i, 'struct')
						let name = name . ' <-- struct ' . i.struct
					elseif has_key(i, 'union')
						let name = name . ' <-- union ' . i.union
					endif
				endif
			else
				let name = i.name . i.signature
				if has_key(i, 'kind') && match('fm', i.kind) >= 0
					let sep = (ft == 'cpp' || ft == 'c')? '::' : '.'
					if has_key(i, 'class')
						let name = i.class . sep . name
					elseif has_key(i, 'struct')
						let name = i.struct . sep. name
					elseif has_key(i, 'union')
						let name = i.struct . sep. name
					endif
				endif
			endif
		elseif has_key(i, 'kind')
			if i.kind == 'd'
				let name = 'macro '. i.name
			elseif i.kind == 'c'
				let name = ((ft == 'vim')? 'command ' : 'class '). i.name
			elseif i.kind == 's'
				let name = 'struct '. i.name
			elseif i.kind == 'u'
				let name = 'union '. i.name
			elseif (match('fpmvt', i.kind) != -1) &&
						\(has_key(i, 'cmd') && i.cmd[0] == '/')
				let tmppat = '\(\<'.i.name.'\>.\{-}\)'
				if index(['c', 'cpp', 'cs', 'java', 'javascript'], ft) >= 0
					" let tmppat = tmppat . ';.*'
				elseif ft == 'python' && (i.kind == 'm' || i.kind == 'f')
					let tmppat = tmppat . ':.*'
				elseif ft == 'tcl' && (i.kind == 'm' || i.kind == 'p')
					let tmppat = tmppat . '\({\)\?$'
				endif
				if i.kind == 'm' && &filetype == 'cpp'
					let tmppat=substitute(tmppat,'^\(.*::\)','\\(\1\\)\\?','')
				endif
				if match(i.cmd[2:-3], tmppat) != -1
					let name=substitute(i.cmd[2:-3], tmppat, '\1', '')
					if i.kind == 't' && name !~ '^\s*typedef\>'
						let name = 'typedef ' . i.name
					endif
				elseif i.kind == 't'
					let name = 'typedef ' . i.name
				elseif i.kind == 'v'
					let name = 'var ' . i.name
				else
					let name = i.name
				endif
				if i.kind == 'm'
					if has_key(i, 'class')
						let name = name . ' <-- class ' . i.class
					elseif has_key(i, 'struct')
						let name = name . ' <-- struct ' . i.struct
					elseif has_key(i, 'union')
						let name = name . ' <-- union ' . i.union
					endif
				endif
				let name = substitute(name, '^\s*\(.\{-}\)\s*$', '\1', '')
				if name[-1:] == ';'
					let name = name[0:-2]
				endif
			else
				let name = i.name
			endif
		else
			let name = i.name
		endif
		let name = substitute(name, '^\s\+', '', '')
		let name = substitute(name, '\s\+$', '', '')
		let name = substitute(name, '\s\+', ' ', 'g')
		let i.func_prototype = name
		let file_line = ''
		if has_key(i, 'filename')
			let file_line = fnamemodify(i.filename, ':t')
			if has_key(i, 'line')
				let file_line .= ':'. i.line
			elseif i.cmd > 0
				let file_line .= ':'. i.cmd
				if i.cmd =~ '^\s*\d\+\s*$'
					let i.line = str2nr(i.cmd)
				endif
			endif
		endif
		let i.file_line = file_line
		let res += [i]
	endfor
	let index = 1
	for i in res
		let name = i.func_prototype
		let file_line = i.file_line
		let desc = name. ' ('.index.'/'.len(res).') '.file_line
		let i.func_desc = desc
		let index += 1
	endfor
	return res
endfunc


"----------------------------------------------------------------------
" find tags
"----------------------------------------------------------------------
function! s:FindTags(bang, tagname, ...)
	let ft = (a:0 > 0)? a:1 : &ft
	let keyword = a:tagname
	let signatures = s:signature(a:tagname, 0, ft)
	if len(signatures) == 0
		redraw
		redrawstatus
		echohl ErrorMsg
		echo "E259: not find '". (a:tagname) ."'"
		echohl NONE
		return 0
	endif
	let ncol = col('.')
	let nrow = line('.')
	let nbuf = winbufnr('%')
	let text = 'ctags "'.keyword.'"'
	let text = "[cscope z: ".text."]"
	let title = "GscopeFind z \"" .keyword.'"'
	let save_local = &l:efm
	let save_global = &g:efm
	let &g:efm = '%f:%l:%m'
	let &l:efm = '%f:%l:%m'
	silent! exec 'cexpr text'
	if has('nvim') == 0 && (v:version >= 800 || has('patch-7.4.2210'))
		call setqflist([], 'a', {'title':title})
	elseif has('nvim') && has('nvim-0.2.2')
		call setqflist([], 'a', {'title':title})
	elseif has('nvim')
		call setqflist([], 'a', title)
	else
		call setqflist([], 'a')
	endif
	for item in signatures
		let t = item.filename . ':'. item.line . ': ' . item.func_prototype
		noautocmd silent caddexpr t
	endfor
	let &g:efm = save_global
	let &l:efm = save_local
	if winbufnr('%') == nbuf
		call cursor(nrow, ncol)
	endif
	if a:bang == 0
		let height = get(g:, 'gutentags_plus_height', 6)
		call s:quickfix_open(height)
	endif
	return 1
endfunc


"----------------------------------------------------------------------
" setup keymaps
"----------------------------------------------------------------------
func! s:FindCwordCmd(cmd, is_file)
	let cmd = ":\<C-U>" . a:cmd
	if a:is_file == 1
		let cmd .= " " . expand('<cfile>')
	else
		let cmd .= " " . expand('<cword>')
	endif
	let cmd .= "\<CR>"
	return cmd
endf

nnoremap <silent> <expr> <Plug>GscopeFindSymbol     <SID>FindCwordCmd('GscopeFind s', 0)
nnoremap <silent> <expr> <Plug>GscopeFindDefinition <SID>FindCwordCmd('GscopeFind g', 0)
nnoremap <silent> <expr> <Plug>GscopeFindCalledFunc <SID>FindCwordCmd('GscopeFind d', 0)
nnoremap <silent> <expr> <Plug>GscopeFindCallingFunc <SID>FindCwordCmd('GscopeFind c', 0)
nnoremap <silent> <expr> <Plug>GscopeFindText       <SID>FindCwordCmd('GscopeFind t', 0)
nnoremap <silent> <expr> <Plug>GscopeFindEgrep      <SID>FindCwordCmd('GscopeFind e', 0)
nnoremap <silent> <expr> <Plug>GscopeFindFile       <SID>FindCwordCmd('GscopeFind f', 1)
nnoremap <silent> <expr> <Plug>GscopeFindInclude    <SID>FindCwordCmd('GscopeFind i', 1)
nnoremap <silent> <expr> <Plug>GscopeFindAssign     <SID>FindCwordCmd('GscopeFind a', 0)
nnoremap <silent> <expr> <Plug>GscopeFindCtag       <SID>FindCwordCmd('GscopeFind z', 0)

if get(g:, 'gutentags_plus_nomap', 0) == 0
	nmap <silent> <leader>cs <Plug>GscopeFindSymbol
	nmap <silent> <leader>cg <Plug>GscopeFindDefinition
	nmap <silent> <leader>cc <Plug>GscopeFindCallingFunc
	nmap <silent> <leader>ct <Plug>GscopeFindText
	nmap <silent> <leader>ce <Plug>GscopeFindEgrep
	nmap <silent> <leader>cf <Plug>GscopeFindFile
	nmap <silent> <leader>ci <Plug>GscopeFindInclude
	nmap <silent> <leader>cd <Plug>GscopeFindCalledFunc
	nmap <silent> <leader>ca <Plug>GscopeFindAssign
	nmap <silent> <leader>cz <Plug>GscopeFindCtag
	nmap <silent> <leader>ck :GscopeKill<cr>
endif


