"======================================================================
"
" asynctasks.vim - 
"
" Created by skywind on 2020/01/16
" Last Modified: 2020/02/10 21:47
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

" global config
if !exists('g:asynctasks_extra_config')
	let g:asynctasks_extra_config = []
endif

" config by vimrc
if !exists('g:asynctasks_tasks')
	let g:asynctasks_tasks = {}
endif

" builtin
if !exists('g:asynctasks_init_tasks')
	let g:asynctasks_init_tasks = 1
endif

" terminal mode: tab/curwin/top/bottom/left/right/external
if !exists('g:asynctasks_term_pos')
	let g:asynctasks_term_pos = 'bottom'
endif

if !exists('g:asynctasks_term_cols')
	let g:asynctasks_term_cols = ''
endif

if !exists('g:asynctasks_term_rows')
	let g:asynctasks_term_rows = ''
endif

if !exists('g:asynctasks_term_focus')
	let g:asynctasks_term_focus = 1
endif


"----------------------------------------------------------------------
" internal object
"----------------------------------------------------------------------
let s:private = { 'cache':{}, 'rtp':{}, 'local':{}, 'tasks':{} }
let s:error = ''
let s:index = 0


"----------------------------------------------------------------------
" internal function
"----------------------------------------------------------------------

" display in cmdline
function! s:errmsg(msg)
	redraw | echo '' | redraw
	echohl ErrorMsg
	echom 'Error: ' . a:msg
	echohl NONE
	let s:index += 1
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
			if !has_key(sections, current)
				let sections[current] = {}
			endif
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
	for marker in split(a:markers, ',')
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
		let output += [s:abspath(name)]
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
		let f = substitute(f, '\/', '\\', 'g')
	else
		let f = substitute(f, '\\', '\/', 'g')
	endif
	let f = substitute(f, '\\', '\/', 'g')
	if len(f) > 1
		let size = len(f)
		if f[size - 1] == '/'
			let f = strpart(f, 0, size - 1)
		endif
	endif
	return f
endfunc


"----------------------------------------------------------------------
" read ini in cache
"----------------------------------------------------------------------
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
	let ininame = name
	let inihome = fnamemodify(name, ':h')
	let special = []
	for sect in obj.keys
		let section = obj.config[sect]
		if stridx(sect, ':') >= 0
			let special += [sect]
		endif
		for key in keys(section)
			let val = section[key]
			let section[key] = s:replace(val, '$(VIM_INIHOME)', inihome)
			let section[key] = s:replace(val, '$(VIM_INIFILE)', ininame)
		endfor
	endfor
	let sys = g:asynctasks_system
	for key in special
		let parts = split(key, ':')
		let name = s:strip((len(parts) >= 1)? parts[0] : '')
		let system = s:strip((len(parts) >= 2)? parts[1] : '')
		if name == '' 
			unlet obj.config[key]
		elseif system == g:asynctasks_system || system == ''
			let obj.config[name] = obj.config[key]
			unlet obj.config[key]
		else
			unlet obj.config[key]
		endif
	endfor
	return obj
endfunc


"----------------------------------------------------------------------
" check requirement
"----------------------------------------------------------------------
function! s:requirement(what)
	if a:what == 'asyncrun'
		if exists(':AsyncRun') == 0
			let t = 'asyncrun is required, install from '
			call s:errmsg(t . '"skywind3000/asyncrun.vim"')
			return 0
		endif
	endif
	return 1
endfunc


"----------------------------------------------------------------------
" merge starry
"----------------------------------------------------------------------
function! s:starry_merge(target, source)
	let g1 = s:strip(get(a:target, 'grep', ''))
	let g2 = s:strip(get(a:source, 'grep', ''))
	if g1 != '' && g2 != ''
		let gg = g1 . ',' . g2
	elseif g1 != '' && g2 == ''
		let gg = g1
	else
		let gg = g2
	endif
	let a:target['grep'] = gg
	return a:target
endfunc


"----------------------------------------------------------------------
" collect config in rtp
"----------------------------------------------------------------------
function! s:collect_rtp_config() abort
	let names = []
	if g:asynctasks_init_tasks != 0
		let name = s:abspath(s:scripthome . '/tools/default.ini')
		if filereadable(name)
			let names += [name]
		endif
	endif
	if g:asynctasks_rtp_config != ''
		let rtp_name = g:asynctasks_rtp_config
		let rtp_name = s:replace(rtp_name, '$(system)', g:asynctasks_system)
		let rtp_name = s:replace(rtp_name, '<system>', g:asynctasks_system)
		for rtp in split(&rtp, ',')
			if rtp != ''
				let path = s:abspath(rtp . '/' . rtp_name)
				if filereadable(path)
					let names += [path]
				endif
			endif
		endfor
	endif
	for name in g:asynctasks_extra_config
		let name = s:abspath(name)
		if filereadable(name)
			let names += [name]
		endif
	endfor
	let s:private.rtp.ini = {'*':{'__name__':'', '__mode__':''}}
	let config = {}
	let s:error = ''
	let starry = s:private.rtp.ini['*']
	for name in names
		let obj = s:cache_load_ini(name)
		if s:error == ''
			for key in keys(obj.config)
				if key != '*'
					let s:private.rtp.ini[key] = obj.config[key]
				else
					call s:starry_merge(starry, obj.config['*'])
				endif
				let s:private.rtp.ini[key].__name__ = name
				let s:private.rtp.ini[key].__mode__ = "global"
			endfor
		else
			call s:errmsg(s:error)
			let s:error = ''
		endif
	endfor
	let config = deepcopy(s:private.rtp.ini)
	for key in keys(g:asynctasks_tasks)
		if key != '*'
			let config[key] = g:asynctasks_tasks[key]
		else
			call s:starry_merge(starry, g:asynctasks_tasks['*'])
		endif
		let config[key].__name__ = 'vimscript'
		let config[key].__mode__ = 'vimscript'
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
	let config = {'*':{'__name__':'', '__mode__':''}}
	let starry = config['*']
	for name in names
		let s:error = ''
		let obj = s:cache_load_ini(name)
		if s:error == ''
			for key in keys(obj.config)
				if key != '*'
					let config[key] = obj.config[key]
				else
					call s:starry_merge(starry, obj.config['*'])
				endif
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
" extract correct command
"----------------------------------------------------------------------
function! s:select_command(config, ft)
	let command = get(a:config, 'command', '')
	for key in keys(a:config)
		let pos = stridx(key, ':')
		if pos < 0
			continue
		endif
		let part = split(key, ':')
		let head = substitute(part[0], '^\s*\(.\{-}\)\s*$', '\1', '')
		if head != 'command'
			continue
		endif
		let text = substitute(part[1], '^\s*\(.\{-}\)\s*$', '\1', '')
		let check = 0
		for ft in split(text, ',')
			let ft = substitute(ft, '^\s*\(.\{-}\)\s*$', '\1', '')
			if ft == a:ft
				let command = a:config[key]
			endif
		endfor
	endfor
	return command
endfunc


"----------------------------------------------------------------------
" fetch all config
"----------------------------------------------------------------------
function! asynctasks#collect_config(path, force)
	let s:index = 0
	let s:error = ''
	let c1 = s:compose_rtp_config(a:force)
	let c2 = s:compose_local_config(a:path)
	let tasks = {'config':{}, 'names':{}, 'avail':[]}
	for cc in [c1, c2]
		for key in keys(cc)
			let tasks.config[key] = cc[key]
		endfor
	endfor
	let avail = []
	let modes = {'global':2, 'vimscript':1, 'local':0}
	for key in keys(tasks.config)
		if key != '*'
			let tasks.names[key] = 1
			let avail += [[key, modes[tasks.config[key].__mode__]]]
		endif
	endfor
	call sort(avail)
	for item in avail
		let tasks.avail += [item[0]]
	endfor
	let s:private.tasks = tasks
	return (s:index == 0)? 0 : -1
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
	let name = substitute(name, '^\s*\(.\{-}\)\s*$', '\1', '')
	let system = substitute(system, '^\s*\(.\{-}\)\s*$', '\1', '')
	return [name, system]
endfunc


"----------------------------------------------------------------------
" format table
"----------------------------------------------------------------------
function! asynctasks#tabulify(rows)
	let content = []
	let rows = []
	let nrows = len(a:rows)
	let ncols = 0
	for row in a:rows
		if len(row) > ncols
			let ncols = len(row)
		endif
	endfor
	if nrows == 0 || ncols == 0
		return content
	endif
	let sizes = repeat([0], ncols)
	let index = range(ncols)
	for row in a:rows
		let newrow = deepcopy(row)
		if len(newrow) < ncols
			let newrow += repeat([''], ncols - len(newrow))
		endif
		for i in index
			let size = strwidth(newrow[i])
			let sizes[i] = (sizes[i] < size)? size : sizes[i]
		endfor
		let rows += [newrow]
	endfor
	for row in rows
		let ni = []
		for i in index
			let x = row[i]
			let size = strwidth(x)
			if size < sizes[i]
				let x = x . repeat(' ', sizes[i] - size)
			endif
			let ni += [x]
		endfor
		let content += [ni]
	endfor
	return content
endfunc


"----------------------------------------------------------------------
" display table
"----------------------------------------------------------------------
function! s:print_table(rows, highmap)
	let content = asynctasks#tabulify(a:rows)
	let index = 0
	for line in content
		let col = 0
		echon (index == 0)? " " : "\n "
		for cell in line
			let key = index . ',' . col
			if !has_key(a:highmap, key)
				echohl None
			else
				exec 'echohl ' . a:highmap[key]
			endif
			echon cell . '  '
			let col += 1
		endfor
		let index += 1
	endfor
	echohl None
endfunc


"----------------------------------------------------------------------
" format parameter
"----------------------------------------------------------------------
function! s:task_option(task)
	let task = a:task
	let opts = {'mode':''}
	if has_key(task, 'cwd')
		let opts.cwd = task.cwd
	endif
	if has_key(task, 'mode')
		let opts.mode = task.mode
	endif
	if has_key(task, 'raw')
		let opts.raw = task.raw
	endif
	if has_key(task, 'save')
		let opts.save = task.save
	endif
	if has_key(task, 'output')
		let output = task.output
		let opts.mode = 'async'
		if output == 'quickfix'
			let opts.mode = 'async'
		elseif output == 'term' || output == 'terminal'
			let pos = g:asynctasks_term_pos
			let gui = get(g:, 'asyncrun_gui', 0)
			if pos == 'vim' || pos == 'bang'
				let opts.mode = 'bang'
			elseif pos == 'quickfix'
				let opts.mode = 'async'
				let opts.raw = 1
			elseif pos != 'external' && pos != 'system' && pos != 'os'
				let opts.mode = 'term'
				let opts.pos = pos
				let opts.cols = g:asynctasks_term_cols
				let opts.rows = g:asynctasks_term_rows
				let opts.focus = g:asynctasks_term_focus
			elseif s:windows && gui != 0
				let opts.mode = 'system'
			else
				let opts.mode = 'term'
				let opts.pos = 'bottom'
				let opts.cols = g:asynctasks_term_cols
				let opts.rows = g:asynctasks_term_rows
				let opts.focus = g:asynctasks_term_focus
			endif
		elseif output == 'quickfix-raw' || output == 'raw'
			let opts.mode = 'async'
			let opts.raw = 1
		elseif output == 'vim'
			let opts.mode = 'bang'
		endif
	endif
	if has_key(task, 'errorformat')
		let opts.errorformat = task.errorformat
		if task.errorformat == ''
			let opts.raw = 1
		endif
	endif
	if has_key(task, 'strip')
		let opts.strip = task.strip
	endif
	for key in ['pos', 'rows', 'cols', 'focus']
		if has_key(task, key)
			let opts[key] = task[key]
		endif
	endfor
	return opts
endfunc


"----------------------------------------------------------------------
" compare version: 0 for equal, 1 for current > require, -1 for <
"----------------------------------------------------------------------
function! asynctasks#version_compare(current, require)
	let current = split(a:current, '\.')
	let require = split(a:require, '\.')
	if len(require) < len(current)
		let require += repeat(['.'], len(current) - len(require))
	elseif len(require) > len(current)
		let current += repeat(['.'], len(require) - len(current))
	endif
	for index in range(len(require))
		let c = str2nr(current[index])
		let r = str2nr(require[index])
		if c > r
			return 1
		elseif c < r
			return -1
		endif
	endfor
	return 0
endfunc


"----------------------------------------------------------------------
" run task
"----------------------------------------------------------------------
function! asynctasks#start(bang, taskname, path)
	let path = (a:path == '')? expand('%:p') : a:path
	if asynctasks#collect_config(path, 1) != 0
		return -1
	endif
	let s:error = ''
	let tasks = s:private.tasks
	if !has_key(tasks.names, a:taskname)
		call s:errmsg('not find task [' . a:taskname . ']')
		return -2
	endif
	let task = tasks.config[a:taskname]
	let ininame = task.__name__
	let source = 'task ['. a:taskname . '] from ' . ininame
	let command = s:select_command(task, &ft)
	if command == ''
		call s:errmsg('no command defined in ' . source)
		return -3
	endif
	if exists(':AsyncRun') == 0
		let t = 'asyncrun is required, install from '
		call s:errmsg(t . '"skywind3000/asyncrun.vim"')
		return -4
	endif
	if exists('*asyncrun#version') == 0
		let t = 'asyncrun is too old, get the latest from '
		call s:errmsg(t . '"skywind3000/asyncrun.vim"')
		return -5
	endif
	let target = '2.3.0'
	if asynctasks#version_compare(asyncrun#version(), target) < 0
		let t = 'asyncrun ' . target . ' or above is required, update from '
		call s:errmsg(t . '"skywind3000/asyncrun.vim"')
		return -6
	endif
	let opts = s:task_option(task)
	let skip = g:asyncrun_skip
	if opts.mode == 'bang' || opts.mode == 2
		" let g:asyncrun_skip = or(g:asyncrun_skip, 2)
	endif
	call asyncrun#run(a:bang, opts, command)
	let g:asyncrun_skip = skip
	return 0
endfunc


"----------------------------------------------------------------------
" list available tasks
"----------------------------------------------------------------------
function! asynctasks#list(path)
	let path = (a:path == '')? expand('%:p') : a:path
	if asynctasks#collect_config(path, 1) != 0
		return -1
	endif
	let tasks = s:private.tasks
	let rows = []
	for task in tasks.avail
		let item = tasks.config[task]
		let command = get(item, 'command', '')
		let ni = {}
		let ni.name = task
		let ni.command = s:select_command(item, &ft)
		let ni.scope = item.__mode__
		let ni.source = item.__name__
		if ni.command != ''
			let rows += [ni]
		endif
	endfor
	return rows
endfunc


"----------------------------------------------------------------------
" list tasks
"----------------------------------------------------------------------
function! s:task_list(path)
	let path = (a:path == '')? expand('%:p') : a:path
	if asynctasks#collect_config(path, 1) != 0
		return -1
	endif
	let tasks = s:private.tasks
	let rows = []
	let rows += [['Task', 'Type', 'Detail']]
	let highmap = {}
	let index = 0
	let highmap['0,0'] = 'Title'
	let highmap['0,1'] = 'Title'
	let highmap['0,2'] = 'Title'
	" let rows += [['----', '----', '------']]
	for task in tasks.avail
		let item = tasks.config[task]
		let command = s:select_command(item, &ft)
		if command != ''
			let rows += [[task, item.__mode__, command]]
			let rows += [['', '', item.__name__]]
		endif
		let highmap[(index * 2 + 1) . ',0'] = 'Keyword'
		let highmap[(index * 2 + 1) . ',1'] = 'Number'
		let highmap[(index * 2 + 1) . ',2'] = 'Statement'
		let highmap[(index * 2 + 2) . ',2'] = 'Comment'
		let index += 1
	endfor
	call s:print_table(rows, highmap)
	" echo highmap
endfunc


"----------------------------------------------------------------------
" config template
"----------------------------------------------------------------------
let s:template = [
	\ '# vim: set noet fenc=utf-8 sts=4 sw=4 ts=4 ft=dosini:',
	\ '',
	\ '# define a new task named "compile-file"',
	\ '[compile-file]',
	\ '',
	\ '# shell command, use quotation for filenames containing spaces',
	\ '# check ":AsyncTaskMacro" to see available macros',
	\ 'command=gcc "$(VIM_FILEPATH)" -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT)"',
	\ '',
	\ '# working directory, can change to $(VIM_ROOT) for project root',
	\ 'cwd=$(VIM_FILEDIR)',
	\ '',
	\ '# output mode, can be one of quickfix, raw and terminal',
	\ '# - quickfix: output to quickfix window',
	\ '# - raw: output to quickfix window without errorformat matching',
	\ '# - terminal: run the command in the internal terminal',
	\ 'output=quickfix',
	\ '',
	\ '# this is for output=quickfix only',
	\ "# if it is omitted, vim's current errorformat will be used.",
	\ 'errorformat=%f:%l:%m',
	\ '',
	\ '# save file before execute',
	\ 'save=1',
	\ '',
	\ ]


"----------------------------------------------------------------------
" edit task
"----------------------------------------------------------------------
function! s:task_edit(mode, path)
	let name = a:path
	if s:requirement('asyncrun') == 0
		return -1
	endif
	if name == ''
		if a:mode ==# '-e'
			let name = asyncrun#get_root('%')
			let name = name . '/' . g:asynctasks_config_name
			let name = fnamemodify(expand(name), ':p')
		else
			let name = expand('~/.vim/' . g:asynctasks_rtp_config)
		endif
	endif
	call inputsave()
	let r = input('(Edit task config): ', name)
	call inputrestore()
	if r == ''
		return -1
	endif
	let newfile = filereadable(name)? 0 : 1
	exec "split " . fnameescape(name)
	exec "setlocal ft=dosini sts=4 sw=4 ts=4 noet"
	if newfile
		exec "normal ggVGx"
		call append(line('.') - 1, s:template)
		setlocal nomodified
	endif
endfunc


"----------------------------------------------------------------------
" macro help 
"----------------------------------------------------------------------
let s:macros = { 
	\ 'VIM_FILEPATH': 'File name of current buffer with full path',
	\ 'VIM_FILENAME': 'File name of current buffer without path',
	\ 'VIM_FILEDIR': 'Full path of current buffer without the file name',
	\ 'VIM_FILEEXT': 'File extension of current buffer',
	\ 'VIM_FILENOEXT': 
		\ 'File name of current buffer without path and extension',
	\ 'VIM_PATHNOEXT':
		\ 'Current file name with full path but without extension',
	\ 'VIM_CWD': 'Current directory',
	\ 'VIM_RELDIR': 'File path relativize to current directory',
	\ 'VIM_RELNAME': 'File name relativize to current directory',
	\ 'VIM_ROOT': 'Project root directory',
	\ 'VIM_CWORD': 'Current word under cursor',
	\ 'VIM_CFILE': 'Current filename under cursor',
	\ 'VIM_GUI': 'Is running under gui ?',
	\ 'VIM_VERSION': 'Value of v:version',
	\ 'VIM_COLUMNS': "How many columns in vim's screen",
	\ 'VIM_LINES': "How many lines in vim's screen", 
	\ 'VIM_SVRNAME': 'Value of v:servername for +clientserver usage',
	\ }


"----------------------------------------------------------------------
" macro list
"----------------------------------------------------------------------
function! s:task_macro()
	let macros = {}
	let macros['VIM_FILEPATH'] = expand("%:p")
	let macros['VIM_FILENAME'] = expand("%:t")
	let macros['VIM_FILEDIR'] = expand("%:p:h")
	let macros['VIM_FILENOEXT'] = expand("%:t:r")
	let macros['VIM_PATHNOEXT'] = expand("%:r")
	let macros['VIM_FILEEXT'] = "." . expand("%:e")
	let macros['VIM_CWD'] = getcwd()
	let macros['VIM_RELDIR'] = expand("%:h:.")
	let macros['VIM_RELNAME'] = expand("%:p:.")
	let macros['VIM_CWORD'] = expand("<cword>")
	let macros['VIM_CFILE'] = expand("<cfile>")
	let macros['VIM_VERSION'] = ''.v:version
	let macros['VIM_SVRNAME'] = v:servername
	let macros['VIM_COLUMNS'] = ''.&columns
	let macros['VIM_LINES'] = ''.&lines
	let macros['VIM_GUI'] = has('gui_running')? 1 : 0
	let macros['VIM_ROOT'] = asyncrun#get_root('%')
    let macros['VIM_HOME'] = expand(split(&rtp, ',')[0])
	let macros['<cwd>'] = macros['VIM_CWD']
	let macros['<root>'] = macros['VIM_ROOT']
	let names = ['FILEPATH', 'FILENAME', 'FILEDIR', 'FILEEXT', 'FILENOEXT']
	let names += ['PATHNOEXT', 'CWD', 'RELDIR', 'RELNAME', 'CWORD', 'CFILE']
	let names += ['VERSION', 'SVRNAME', 'COLUMNS', 'LINES', 'GUI', 'ROOT']
	let rows = []
	let rows += [['Macro', 'Detail', 'Value']]
	let highmap = {}
	let highmap['0,0'] = 'Title'
	let highmap['0,1'] = 'Title'
	let highmap['0,2'] = 'Title'
	let index = 1
	for nn in names
		let name = 'VIM_' . nn
		let rows += [['$(' . name . ')', s:macros[name], macros[name]]]
		" let rows += [['', macros[name]]]
		let highmap[index . ',0'] = 'Keyword'
		let highmap[index . ',1'] = 'Statement'
		let highmap[index . ',2'] = 'Comment'
		let index += 1
	endfor
	call s:print_table(rows, highmap)
endfunc


"----------------------------------------------------------------------
" command AsyncTask
"----------------------------------------------------------------------
function! asynctasks#cmd(bang, ...)
	let taskname = (a:0 >= 1)? (a:1) : ''
	let path = (a:0 >= 2)? (a:2) : ''
	if taskname == ''
		call s:errmsg('require task name')
		return -1
	elseif taskname == '-h'
		echo 'usage:  :AsyncTask <operation>'
		echo 'operations:'
		echo '    :AsyncTask {taskname}      - run specific task'
		echo '    :AsyncTask -l              - list tasks'
		echo '    :AsyncTask -h              - show this help'
		echo '    :AsyncTask -e              - edit local task in project root'
		echo '    :AsyncTask -E              - edit global task in ~/.vim'
		echo '    :AsyncTask -m              - display command macros'
		return 0
	elseif taskname == '-l'
		call s:task_list('')
		return 0
	elseif taskname ==# '-e' || taskname ==# '-E'
		call s:task_edit(taskname, path)
		return 0
	elseif taskname == '-m'
		call s:task_macro()
		return 0
	endif
	call asynctasks#start(a:bang, taskname, '')
endfunc


"----------------------------------------------------------------------
" command
"----------------------------------------------------------------------

command! -bang -nargs=* AsyncTask
			\ call asynctasks#cmd('<bang>', <q-args>)


"----------------------------------------------------------------------
" help commands
"----------------------------------------------------------------------
command! -bang -nargs=0 AsyncTaskEdit
			\ call asynctasks#cmd('', ('<bang>' == '')? '-e' : '-E')

command! -nargs=0 AsyncTaskList 
			\ call asynctasks#cmd('', '-l')

command! -nargs=0 AsyncTaskMacro
			\ call asynctasks#cmd('', '-m')


"----------------------------------------------------------------------
" benchmark
"----------------------------------------------------------------------
function! asynctasks#timing()
	let ts = reltime()
	" call s:collect_rtp_config()
	call asynctasks#collect_config('.', 1)
	let tt = reltimestr(reltime(ts))
	echo s:private.rtp.config
	return tt
endfunc


