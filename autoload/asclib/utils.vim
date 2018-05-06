let s:windows = asclib#common#windows

"----------------------------------------------------------------------
" write log
"----------------------------------------------------------------------
function! asclib#utils#log(text, ...) abort
	let text = a:text . ' '. join(a:000, ' ')
	let time = strftime('%Y-%m-%d %H:%M:%S')
	let name = 'm'. strpart(time, 0, 10) . '.log'
	let name = substitute(name, '-', '', 'g')
	let home = expand('~/.vim/logs')
	let text = '['.time.'] ' . text
	let name = home .'/'. name
	if !exists('*writefile')
		return 0
	endif
	if !isdirectory(home)
		silent! call mkdir(home, 'p')
	endif
	call writefile([text . "\n"], name, 'a')
	return 1
endfunc


"----------------------------------------------------------------------
" call terminal.py
"----------------------------------------------------------------------
function! asclib#utils#terminal(mode, cmd, wait, ...) abort
	let home = asclib#setting#script_home()
	let script = asclib#path_join(home, '../../lib/terminal.py')
	let script = fnamemodify(script, ':p')
	let cmd = ''
	if a:mode != ''
		let cmd .= ' --terminal='.a:mode
	endif
	if a:wait
		let cmd .= ' -w'
	endif
	if a:0 >= 1
		let cmd .= ' --cwd='.a:1
	endif
	if a:0 >= 2
		let cmd .= ' --profile='.a:2
	endif
	let cygwin = asclib#setting#get('cygwin', '')
	if cygwin != ''
		let cmd .= ' --cygwin='.shellescape(cygwin)
	endif
	if cmd != ''
		let cmd .= ' '
	endif
	let cmd = 'python '.shellescape(script). ' ' .cmd . a:cmd
	exec 'VimMake -mode=5 '.cmd
endfunc



"----------------------------------------------------------------------
" dash / zeal
"----------------------------------------------------------------------
function! asclib#utils#dash(language, keyword)
	let zeal = asclib#setting#get('zeal', 'zeal.exe')
	if !executable(zeal)
		call asclib#errmsg('cannot find executable: '.zeal)
		return
	endif
	let url = 'dash://'.a:language.':'.a:keyword
	if asclib#setting#has_windows()
		silent! exec '!start '.shellescape(zeal). ' '.shellescape(url)
	else
		call system('open '.shellescape(url).' &')
	endif
endfunc


function! asclib#utils#dash_ft(ft, keyword)
	let groups = g:asclib#dash#module.groups
	let langs = get(groups, a:ft, [])
	call asclib#utils#dash(join(langs, ','), a:keyword)
endfunc


"----------------------------------------------------------------------
" invoke shell.py
"----------------------------------------------------------------------
function! asclib#utils#shell_invoke(mode, cmd, ...)
	let home = asclib#setting#script_home()
	let script = asclib#path_join(home, '../../lib/shell.py')
	let script = fnamemodify(script, ':p')
	let cmdline = 'python ' . shellescape(script) . ' ' . a:cmd
	for i in range(a:0)
		let cmdline .= ' ' . shellescape(a:{i + 1})
	endfor
	exec 'AsyncRun -raw=1 -mode='.a:mode.' '.cmdline
endfunc


"----------------------------------------------------------------------
" shell - gdb 
"----------------------------------------------------------------------
function! asclib#utils#emacs_gdb(exename)
	if asclib#setting#has_windows()
		let emacs = asclib#setting#get('emacs', 'runemacs.exe')
		let gdb = asclib#setting#get('gdb', 'gdb.exe')
		call asclib#utils#shell_invoke(5, '-E', emacs, gdb, a:exename)
	else
		let emacs = asclib#setting#get('emacs', 'emacs')
		let gdb = asclib#setting#get('gdb', 'gdb')
		call asclib#utils#shell_invoke(2, '-E', emacs, gdb, a:exename)
	endif
endfunc


"----------------------------------------------------------------------
" list script
"----------------------------------------------------------------------
function! s:list_script()
	let path = get(g:, 'vimmake_path', expand('~/.vim/script'))
	let names = []
	if s:windows
		for name in split(glob(vimmake#path_join(path, '*.cmd')), '\n')
			let item = {}
			let item.name = fnamemodify(name, ':t')
			let item.path = name
			let item.cmd = 'call '. shellescape(name)
			if item.name =~ '^vimmake\.'
				continue
			endif
			let names += [item]
		endfor
		for name in split(glob(vimmake#path_join(path, '*.bat')), '\n')
			let item = {}
			let item.name = fnamemodify(name, ':t')
			let item.path = name
			let item.cmd = 'call '. shellescape(name)
			let names += [item]
		endfor
	else
		for name in split(glob(vimmake#path_join(path, '*.sh')), '\n')
			let item = {}
			let item.name = fnamemodify(name, ':t')
			let item.path = name
			let item.cmd = 'bash ' . shellescape(name)
			let names += [item]
		endfor
	endif

	for name in split(glob(vimmake#path_join(path, '*.py')), '\n')
		let item = {}
		let item.name = fnamemodify(name, ':t')
		let item.path = name
		let item.cmd = 'python ' . shellescape(name)
		let names += [item]
	endfor

	for name in split(glob(vimmake#path_join(path, '*.rb')), '\n')
		let item = {}
		let item.name = fnamemodify(name, ':t')
		let item.path = name
		let item.cmd = 'ruby ' . shellescape(name)
		let names += [item]
	endfor

	for name in split(glob(vimmake#path_join(path, '*.pl')), '\n')
		let item = {}
		let item.name = fnamemodify(name, ':t')
		let item.path = name
		let item.cmd = 'perl ' . shellescape(name)
		let names += [item]
	endfor

	return names
endfunc


function! asclib#utils#script_menu()
	if &bt == 'nofile' && &ft == 'quickmenu'
		call quickmenu#toggle(0)
		return
	endif
	call quickmenu#current('script')
	call quickmenu#reset()

	call quickmenu#append('# Scripts', '')
	
	for item in s:list_script()
		let cmd = 'VimMake -raw ' . item.cmd
		call quickmenu#append(item.name, cmd, 'run ' . item.name)	
	endfor

	call quickmenu#toggle('script')
endfunc


"----------------------------------------------------------------------
" search gtags config
"----------------------------------------------------------------------
function! asclib#utils#gtags_search_conf()
	let rc = get(g:, 'gutentags_plus_rc', '')
	if rc != ''
		if filereadable(rc)
			return asclib#path#abspath(rc)
		endif
	endif
	let rc = asclib#path#abspath(expand('~/.globalrc'))
	if filereadable(rc)
		return rc
	endif
	let rc = asclib#path#abspath(expand('~/.gtags'))
	if filereadable(rc)
		return rc
	endif
	if g:asclib#common#unix != 0
		let rc = '/etc/gtags.conf'
		if filereadable(rc)
			return rc
		endif
		let rc = '/usr/local/etc/gtags.conf'
		if filereadable(rc)
			return rc
		endif
	endif
	let gtags = get(g:, 'gutentags_gtags_executable', 'gtags')
	let gtags = asclib#path#executable(gtags)
	if gtags == ''
		return ''
	endif
	let ghome = asclib#path#dirname(gtags)
	let rc = asclib#path#join(ghome, '../share/gtags/gtags.conf')
	let rc = asclib#path#abspath(rc)
	if filereadable(rc)
		return rc
	endif
	return ''
endfunc




