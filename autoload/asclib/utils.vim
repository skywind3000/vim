
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


