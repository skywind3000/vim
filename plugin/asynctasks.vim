"======================================================================
"
" asynctasks.vim - 
"
" Created by skywind on 2020/01/16
" Last Modified: 2020/01/16 00:50:59
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
" internal variables
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')
let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h:h')


"----------------------------------------------------------------------
" default values
"----------------------------------------------------------------------

" system identifier
if !exists('g:asynctasks_system')
	let g:asynctasks_system = (s:windows)? 'win' : 'unix'
endif

" local config
if !exists('g:asynctasks_config_name')
	let g:asynctasks_config_name = '.tasks'
endif

" global config in every runtimepath
if !exists('g:asynctasks_rtp_config')
	let g:asynctasks_rtp_config = 'tasks.ini'
endif

" config by vimrc
if !exists('g:asynctasks_tasks')
	let g:asynctasks_tasks = {}
endif


"----------------------------------------------------------------------
" internal object
"----------------------------------------------------------------------
let s:private = { 'cache':{}, 'rtp':{}, 'local':{}, 'tasks':{} }
let s:error = ''


"----------------------------------------------------------------------
" internal function
"----------------------------------------------------------------------

" display in cmdline
function! s:errmsg(msg)
	redraw | echo '' | redraw
	echohl ErrorMsg
	echom a:msg
	echohl NONE
endfunc

" trim leading & trailing spaces
function! s:strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunc

" replace string
function! s:replace(text, old, new)
	let l:data = split(a:text, a:old, 1)
	return join(l:data, a:new)
endfunc

" load ini file
function! s:readini(source)
	if type(a:source) == type('')
		if !filereadable(a:source)
			return -1
		endif
		let content = readfile(a:source)
	elseif type(a:source) == type([])
		let content = a:source
	else
		return -2
	endif
	let sections = {}
	let current = 'default'
	let index = 0
	for line in content
		let t = substitute(line, '^\s*\(.\{-}\)\s*$', '\1', '')
		let index += 1
		if t == ''
			continue
		elseif t =~ '^[;#].*$'
			continue
		elseif t =~ '^\[.*\]$'
			let current = substitute(t, '^\[\s*\(.\{-}\)\s*\]$', '\1', '')
		else
			let pos = stridx(t, '=')
			if pos >= 0
				let key = strpart(t, 0, pos)
				let val = strpart(t, pos + 1)
				let key = substitute(key, '^\s*\(.\{-}\)\s*$', '\1', '')
				let val = substitute(val, '^\s*\(.\{-}\)\s*$', '\1', '')
				if !has_key(sections, current)
					let sections[current] = {}
				endif
				let sections[current][key] = val
			else
				return index
			endif
		endif
	endfor
	return sections
endfunc

" returns nearest parent directory contains one of the markers
function! s:find_root(name, markers, strict)
	let name = fnamemodify((a:name != '')? a:name : bufname(), ':p')
	let finding = ''
	" iterate all markers
	for marker in split(g:projectile#marker, ',')
		if marker != ''
			" search as a file
			let x = findfile(marker, name . '/;')
			let x = (x == '')? '' : fnamemodify(x, ':p:h')
			" search as a directory
			let y = finddir(marker, name . '/;')
			let y = (y == '')? '' : fnamemodify(y, ':p:h:h')
			" which one is the nearest directory ?
			let z = (strchars(x) > strchars(y))? x : y
			" keep the nearest one in finding
			let finding = (strchars(z) > strchars(finding))? z : finding
		endif
	endfor
	if finding == ''
		return (a:strict == 0)? fnamemodify(name, ':h') : ''
	endif
	return fnamemodify(finding, ':p')
endfunc

" find project root
function! s:project_root(name, strict)
	let markers = ['.project', '.git', '.hg', '.svn', '.root']
	if exists('g:asyncrun_rootmarks')
		let markers = g:asyncrun_rootmarks
	endif
	return s:find_root(a:name, markers, a:strict)
endfunc

" change directory in a proper way
function! s:chdir(path)
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	silent execute cmd . ' '. fnameescape(a:path)
endfunc

" search files upwards
function! s:search_parent(name, cwd)
	let finding = findfile(a:name, a:cwd . '/;', -1)
	let output = []
	for name in finding
		let name = fnamemodify(name, ':p')
		let output += [name]
	endfor
	return output
endfunc

" get absolute path
function! s:abspath(path)
	let f = a:path
	if f =~ "'."
		try
			redir => m
			silent exe ':marks' f[1]
			redir END
			let f = split(split(m, '\n')[-1])[-1]
			let f = filereadable(f)? f : ''
		catch
			let f = '%'
		endtry
	endif
	let f = (f != '%')? f : expand('%')
	let f = fnamemodify(f, ':p')
	if s:windows != 0
		let f = substitute(f, "\\", '/', 'g')
	endif
	if len(f) > 1
		let size = len(f)
		if f[size - 1] == '/'
			let f = strpart(f, 0, size - 1)
		endif
	endif
	return f
endfunc

" read ini
function! s:cache_load_ini(name)
	let name = (stridx(a:name, '~') >= 0)? expand(a:name) : a:name
	let name = s:abspath(name)
	let p1 = name
	if s:windows || has('win32unix')
		let p1 = tr(tolower(p1), "\\", '/')
	endif
	let ts = getftime(name)
	if ts < 0
		let s:error = 'cannot load ' . a:name
		return -1
	endif
	if has_key(s:private.cache, p1)
		let obj = s:private.cache[p1]
		if ts <= obj.ts
			return obj
		endif
	endif
	let config = s:readini(name)
	if type(config) != v:t_dict
		let s:error = 'syntax error in '. a:name . ' line '. config
		return config
	endif
	let s:private.cache[p1] = {}
	let obj = s:private.cache[p1]
	let obj.ts = ts
	let obj.name = name
	let obj.config = config
	let obj.keys = keys(config)
	let home = fnamemodify(name, ':h')
	for sect in obj.keys
		let section = obj.config[sect]
		for key in keys(section)
			let val = section[key]
			let section[key] = s:replace(val, '$(CFGHOME)', home)
		endfor
	endfor
	return obj
endfunc


"----------------------------------------------------------------------
" collect config in rtp
"----------------------------------------------------------------------
function! s:collect_rtp_config() abort
	let names = []
	for rtp in split(&rtp, ',')
		if rtp != ''
			let path = s:abspath(rtp . '/' . g:asynctasks_rtp_config)
			if filereadable(path)
				let names += [path]
			endif
		endif
	endfor
	let s:private.rtp.ini = {}
	let config = {}
	let s:error = ''
	for name in names
		let obj = s:cache_load_ini(name)
		if s:error == ''
			for key in keys(obj.config)
				let s:private.rtp.ini[key] = obj.config[key]
				let s:private.rtp.ini[key].__name__ = name
				let s:private.rtp.ini[key].__mode__ = "rtp"
			endfor
		else
			call s:errmsg(s:error)
			let s:error = ''
		endif
	endfor
	let config = deepcopy(s:private.rtp.ini)
	for key in keys(g:asynctasks_tasks)
		let config[key] = g:asynctasks_tasks[key]
		let config[key].__name__ = 'vim'
		let config[key].__mode__ = 'vim'
	endfor
	let s:private.rtp.config = config
	return s:private.rtp.config
endfunc


"----------------------------------------------------------------------
" fetch rtp config
"----------------------------------------------------------------------
function! s:compose_rtp_config(force)
	if (!has_key(s:private.rtp, 'config')) || a:force != 0
		call s:collect_rtp_config()
	endif
	return s:private.rtp.config
endfunc


"----------------------------------------------------------------------
" fetch local config
"----------------------------------------------------------------------
function! s:compose_local_config(path)
	let names = s:search_parent(g:asynctasks_config_name, a:path)
	let config = {}
	for name in names
		let s:error = ''
		let obj = s:cache_load_ini(name)
		if s:error == ''
			for key in keys(obj.config)
				let config[key] = obj.config[key]
				let config[key].__name__ = name
				let config[key].__mode__ = 'local'
			endfor
		else
			call s:errmsg(s:error)
			let s:error = ''
		endif
	endfor
	let s:private.local.config = config
	return config
endfunc


"----------------------------------------------------------------------
" fetch all config
"----------------------------------------------------------------------
function! asynctasks#collect_config(path, force)
	let c1 = s:compose_rtp_config(a:force)
	let c2 = s:compose_local_config(a:path)
	let tasks = {'config':{}, 'names':{}, 'avail':[]}
	for cc in [c1, c2]
		for key in keys(cc)
			let tasks.config[key] = cc[key]
		endfor
	endfor
	for key in keys(tasks.config)
		let parts = split(key, ':')
		let name = (len(parts) >= 1)? parts[0] : ''
		let system = (len(parts) >= 2)? parts[1] : ''
		if system == ''
			let tasks.avail += [key]
		elseif system == g:asynctasks_system
			let tasks.avail += [key]
		endif
	endfor
	let s:private.tasks = tasks
endfunc


"----------------------------------------------------------------------
" get project root
"----------------------------------------------------------------------
function! asynctasks#project_root(name, ...)
	return s:project_root(a:name, (a:0 == 0)? 0 : (a:1))
endfunc


"----------------------------------------------------------------------
" split section name:system
"----------------------------------------------------------------------
function! asynctasks#split(name)
	let parts = split(name, ':')
	let name = (len(parts) >= 1)? parts[0] : ''
	let system = (len(parts) >= 2)? parts[1] : ''
	return [name, system]
endfunc


"----------------------------------------------------------------------
" read all profile
"----------------------------------------------------------------------
function! asynctasks#cache_load(name)
	let s:error = ''
	let s = s:cache_load_ini(a:name)
	if s:error != ''
		echo "ERROR: " . s:error
	endif
	return s
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! asynctasks#rtp_config()
	let ts = reltime()
	" call s:collect_rtp_config()
	call asynctasks#collect_config('.', 1)
	let tt = reltimestr(reltime(ts))
	echo s:private.rtp.config
	return tt
endfunc



