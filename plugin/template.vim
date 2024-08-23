"======================================================================
"
" template.vim - 
"
" Created by skywind on 2023/09/12
" Last Modified: 2023/09/18 02:36
"
"======================================================================


" template path in every runtime path
let g:template_name = get(g:, 'template_name', 'template')

" absolute path list
let g:template_path = get(g:, 'template_path', ['~/.vim/template'])

" absolute path for :TemplateEdit
let g:template_edit = get(g:, 'template_edit', '~/.vim/template')

" set to 1 to insert above cursor when using :Template! {name}
let g:template_above = get(g:, 'template_above', 0)

" edit split mode: 'auto', 'vert', 'tab'
let g:template_split = get(g:, 'template_split', 'auto')


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:scripthome = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')


"----------------------------------------------------------------------
" list template directories
"----------------------------------------------------------------------
function! s:template_dirs() abort
	let dirlist = []
	let root = s:scripthome . '/site/template'
	if isdirectory(root)
		call add(dirlist, tr(root, '\', '/'))
	endif
	if g:template_edit != ''
		let path = expand(g:template_edit)
		if path != root
			call add(dirlist, path)
		endif
	endif
	for rtp in split(&rtp, ',')
		let t = rtp . '/' . g:template_name
		if isdirectory(t)
			call add(dirlist, tr(t, '\', '/'))
		endif
	endfor
	let loc_list = []
	if type(g:template_path) == type('')
		let loc_list = split(g:template_path, ',')
	elseif type(g:template_path) == type([])
		let loc_list = g:template_path
	elseif type(g:template_path) == type({})
		let loc_list = keys(g:template_path)
	endif
	if exists('b:template_path')
		if type(b:template_path) == type('')
			call extend(loc_list, split(b:template_path, ','))
		elseif type(b:template_path) == type([])
			call extend(loc_list, b:template_path)
		elseif type(b:template_path) == type({})
			call extend(loc_list, keys(b:template_path))
		endif
	endif
	for t in loc_list
		let t = expand(t)
		if t != '' && isdirectory(t)
			call add(dirlist, tr(t, '\', '/'))
		endif
	endfor
	return dirlist
endfunc


"----------------------------------------------------------------------
" list available templates
"----------------------------------------------------------------------
function! s:template_list(filetype) abort
	let dirs = s:template_dirs()
	let templates = {}
	for base in dirs
		let path = base
		if a:filetype != ''
			let path = base . '/' . (a:filetype)
		endif
		if !isdirectory(path)
			continue
		endif
		let filelist = globpath(path, '*.txt', 1, 1)
		for name in filelist
			let main = fnamemodify(name, ':t:r')
			let templates[main] = name
		endfor
	endfor
	return templates
endfunc


"----------------------------------------------------------------------
" expand text
"----------------------------------------------------------------------
function! s:text_expand(text, mark_open, mark_close, macros) abort
	let mark_open = a:mark_open
	let mark_close = a:mark_close
	let size_open = strlen(mark_open)
	let size_close = strlen(mark_close)
	let text = a:text
	while 1
		let p1 = stridx(text, mark_open)
		if p1 < 0
			break
		endif
		let p2 = stridx(text, mark_close, p1 + size_open)
		if p2 < 0
			break
		endif
		let before = strpart(text, 0, p1)
		let body = strpart(text, p1 + size_open, p2 - p1 - size_open)
		let after = strpart(text, p2 + size_close)
		let name = matchstr(body, '^%\zs.*\ze%$')
		let replace = '<ERROR>'
		if name != '' && has_key(a:macros, name)
			let replace = a:macros[name]
		else
			try
				let replace = printf('%s', eval(body))
			catch
				let replace = v:exception
			endtry
		endif
		let text = before . replace . after
	endwhile
	return text
endfunc


"----------------------------------------------------------------------
" create environ
"----------------------------------------------------------------------
function! s:expand_macros()
	let macros = {}
	let macros['FILEPATH'] = expand("%:p")
	let macros['FILENAME'] = expand("%:t")
	let macros['FILEDIR'] = expand("%:p:h")
	let macros['FILENOEXT'] = expand("%:t:r")
	let macros['PATHNOEXT'] = expand("%:p:r")
	let macros['FILEEXT'] = "." . expand("%:e")
	let macros['FILETYPE'] = (&filetype)
	let macros['CWD'] = getcwd()
	let macros['RELDIR'] = expand("%:h:.")
	let macros['RELNAME'] = expand("%:p:.")
	let macros['CWORD'] = expand("<cword>")
	let macros['CFILE'] = expand("<cfile>")
	let macros['CLINE'] = line('.')
	let macros['VERSION'] = ''.v:version
	let macros['SVRNAME'] = v:servername
	let macros['COLUMNS'] = ''.&columns
	let macros['LINES'] = ''.&lines
	let macros['GUI'] = has('gui_running')? 1 : 0
	let macros['ROOT'] = ''
	let macros['HOME'] = expand(split(&rtp, ',')[0])
	let macros['PRONAME'] = ''
	let macros['DIRNAME'] = fnamemodify(macros['FILEDIR'], ':t')
	let macros['CWDNAME'] = fnamemodify(macros['CWD'], ':t')
	let macros['CLASSNAME'] = macros['FILENOEXT']
	let macros['GUARD'] = toupper(tr(macros['FILENAME'], '.', '_'))
	let macros['YEAR'] = strftime('%Y')
	let macros['MONTH'] = strftime('%m')
	let macros['DAY'] = strftime('%d')
	let macros['TIME'] = strftime('%H:%M')
	let macros['DATE'] = strftime('%Y-%m-%d')
	let macros['USER'] = get(g:, 'template_user', 'NONAME')
	if macros['GUARD'] != ''
		let t = tr(macros['GUARD'], '-', '_')
		let macros['GUARD'] = '_' . t . '_'
	endif
	if expand("%:e") == ''
		let macros['FILEEXT'] = ''
	endif
	let t = expand('~')
	if t != ''
		let macros['USER'] = fnamemodify(t, ':t')
	endif
	if exists('*asyncrun#get_root')
		let macros['ROOT'] = asyncrun#get_root('%')
		let macros['PRONAME'] = fnamemodify(macros['ROOT'], ':t')
	endif
	return macros
endfunc


"----------------------------------------------------------------------
" load template
"----------------------------------------------------------------------
function! s:template_load(filetype, name) abort
	let templates = s:template_list(a:filetype)
	if !has_key(templates, a:name)
		return 0
	endif
	let textlist = []
	let content = readfile(templates[a:name])
	let macros = s:expand_macros()
	for text in content
		let p1 = stridx(text, '`')
		if p1 >= 0
			let text = s:text_expand(text, '`', '`', macros)
		endif
		call add(textlist, text)
	endfor
	return textlist
endfunc


"----------------------------------------------------------------------
" :Template[!] [filetype/]{name}
"----------------------------------------------------------------------
function! s:Template(bang, name, preview)
	if a:name == ''
		echohl ErrorMsg
		echo 'ERROR: template name required'
		echohl None
		return 0
	endif
	let part = split(a:name, '/', 1)
	if len(part) == 1
		let name = part[0]
		let ft = &ft
	else
		let name = part[1]
		let ft = part[0]
	endif
	let content = s:template_load(ft, name)
	if type(content) == type(0)
		echohl ErrorMsg
		echo 'ERROR: template not find: ' . a:name
		echohl None
		return 0
	endif
	if &modifiable == 0 && a:preview == 0
		echohl ErrorMsg
		echo "ERROR: Cannot make changes, 'modifiable' is off"
		echohl None
		return 0
	endif
	if a:preview != 0
		for text in content
			if text == ''
				echo ' '
			else
				echo text
			endif
		endfor
	elseif a:bang == 0
		let bid = bufnr('%')
		silent call deletebufline(bid, 1, '$')
		silent call setbufline(bid, 1, content)
	else
		if g:template_above == 0
			call append('.', content)
		else
			call append(line('.') - 1, content)
		endif
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" :TemplateEdit [filetype/]{name}
"----------------------------------------------------------------------
function! s:TemplateEdit(mods, name)
	if a:name == ''
		echohl ErrorMsg
		echo 'ERROR: template name required'
		echohl None
		return 1
	endif
	let part = split(a:name, '/', 1)
	if len(part) == 1
		let name = part[0]
		let ft = &ft
	else
		let name = part[1]
		let ft = part[0]
	endif
	" echo printf("%s '%s'", type(g:template_edit), g:template_edit)
	if g:template_edit == ''
		echohl ErrorMsg
		echo 'ERROR: variable g:template_edit is empty'
		echohl None
		return 2
	endif
	let home = fnamemodify(g:template_edit . '/', ':p')
	let home = home . ((ft == '')? '' : (ft . '/'))
	let home = tr(home, '\', '/')
	if !isdirectory(home)
		try
			call mkdir(home, 'p')
		catch
			echohl ErrorMsg
			echo v:exception
			echohl None
			return 3
		endtry
	endif
	if !isdirectory(home)
		echohl ErrorMsg
		echo 'ERROR: failed to create: ' . home
		echohl None
		return 3
	endif
	let path = printf('%s%s.txt', home, name)
	let name = fnameescape(path)
	let mods = g:template_split
	let newfile = (filereadable(path) == 0)? 1 : 0
	let savebid = bufnr('%')
	let cs = &commentstring
	let oldft = &ft
	if a:mods != ''
		if a:mods != 'auto'
			exec a:mods . ' split ' . name
		elseif winwidth(0) >= 160
			exec 'vert split ' . name
		else
			exec 'split ' . name
		endif
	elseif mods == ''
		exec 'split ' . name
	elseif mods == 'auto'
		if winwidth(0) >= 160
			exec 'vert split ' . name
		else
			exec 'split ' . name
		endif
	elseif mods == 'tab'
		exec 'tabe ' . name
	else
		exec mods . ' split ' . name
	endif
	if savebid != bufnr('%') && ft != ''
		exec 'setlocal ft=' . ft
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" interface
"----------------------------------------------------------------------
function! template#list_names(ft) abort
	return s:template_list(a:ft)
endfunc


"----------------------------------------------------------------------
" command complete
"----------------------------------------------------------------------
function! s:complete(ArgLead, CmdLine, CursorPos)
	let candidate = []
	if stridx(a:ArgLead, '/') < 0
		let templates = s:template_list(&ft)
		let names = keys(templates)
	else
		let part = split(a:ArgLead, '/', 1)
		let ft = part[0]
		let templates = s:template_list(ft)
		let names = []
		for temp in keys(templates)
			call add(names, ft . '/' . temp)
		endfor
	endif
	call sort(names)
	for name in names
		if stridx(name, a:ArgLead) == 0
			let candidate += [name]
		endif
	endfor
	return candidate
endfunc


"----------------------------------------------------------------------
" command defintion
"----------------------------------------------------------------------
command! -bang -nargs=1 -range=0 -complete=customlist,s:complete 
			\ Template call s:Template(<bang>0, <q-args>, 0)

command! -bang -nargs=1 -range=0 -complete=customlist,s:complete 
			\ TemplatePreview call s:Template(<bang>0, <q-args>, 1)

command! -bang -nargs=1 -range=0 -complete=customlist,s:complete 
			\ TemplateEdit  call s:TemplateEdit('<mods>', <q-args>)



