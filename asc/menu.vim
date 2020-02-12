"======================================================================
"
" menu.vim - 
"
" Created by skywind on 2017/07/06
" Last Modified: 2017/07/06 16:59:26
"
"======================================================================



"----------------------------------------------------------------------
" internal help
"----------------------------------------------------------------------

function! menu#FindInProject()
	let p = vimmake#get_root('%')
	echohl Type
	call inputsave()
	let t = input('find word ('. p.'): ', expand('<cword>'))
	call inputrestore()
	echohl None
	redraw | echo "" | redraw
	if strlen(t) > 0
		silent exec "GrepCode! ".fnameescape(t)
		call asclib#quickfix_title('- searching "'. t. '"')
	endif
endfunc

function! menu#CodeCheck()
	if &ft == 'python'
		call asclib#lint_pylint('')
	elseif &ft == 'c' || &ft == 'cpp'
		call asclib#lint_cppcheck('')
	else
		call asclib#errmsg('file type unsupported, only support python/c/cpp')
	endif
endfunc

function! menu#DelimitSwitch(on)
	if a:on
		exec "DelimitMateOn"
	else
		exec "DelimitMateOff"
	endif
endfunc

function! menu#TogglePaste()
	if &paste
		set nopaste
	else
		set paste
	endif
endfunc

function! menu#CurrentWord(limit)
	let text = expand('<cword>')
	if len(text) < a:limit
		return text
	endif
	return text[:a:limit] . '..'
endfunc

function! menu#CurrentFile(limit)
	let text = expand('%:t')
	if len(text) < a:limit
		return text
	endif
	return text[:a:limit] . '..'
endfunc

function! menu#DiffSplit()
	call asclib#ask_diff()
endfunc

function! menu#EditTool()
	let text = input('Enter tool name: ')
	redraw | echo '' | redraw
	if text == ''
		return
	endif
	exec 'EditTool! '.fnameescape(text)
endfunc

function! menu#WinOpen(what)
	let root = expand('%:p:h')
	let cd = haslocaldir()? 'lcd ' : 'cd '
	let cwd = getcwd()
	exec cd . root
	if a:what == 'cmd'
		exec "silent !start cmd.exe"
	else
		exec "silent !start /b cmd.exe /C start ."
	endif
	exec cd . cwd
endfunc

function! menu#Escope(what)
	let p = expand('%')
	let t = expand('<cword>')
	let m = {}
	let m["s"] = "string symbol"
	let m['g'] = 'definition'
	let m['d'] = 'functions called by this'
	let m['c'] = 'functions calling this'
	let m['t'] = 'string'
	let m['e'] = 'egrep pattern'
	let m['f'] = 'file'
	let m['i'] = 'files #including this file'
	let m['a'] = 'places where this symbol is assigned'
	if a:what == 'f' || a:what == 'i'
		let t = expand('<cfile>')
	endif
	echohl Type
	call inputsave()
	let t = input('find '.m[a:what].' of ('. p.'): ', t)
	call inputrestore()
	echohl None
	redraw | echo "" | redraw
	if t == ''
		return 0
	endif
	exec 'GscopeFind '. a:what. ' ' . fnameescape(t)
endfunc


function! menu#WinHelp(help)
	let t = expand('<cword>')
	echohl Type
	call inputsave()
	let t = input('Search help of ('. fnamemodify(a:help, ':t').'): ', t)
	call inputrestore()
	echohl None
	redraw | echo "" | redraw
	if t == ''
		return 0
	endif
	let extname = tolower(fnamemodify(a:help, ':e'))
	if extname == 'hlp'
		call asclib#open_win32_help(a:help, t)
	elseif extname == 'chm'
		call asclib#open_win32_chm(a:help, t)
	else
		echo "unknow filetype"
	endif
endfunc

function! menu#DashHelp()
	let t = expand('<cword>')
	echohl Type
	call inputsave()
	let t = input('Search help of ('. &ft .'): ', t)
	call inputrestore()
	echohl None
	redraw | echo "" | redraw
	if t == ''
		return 0
	endif
	call asclib#utils#dash_ft(&ft, t)
endfunc


function! menu#ToolHelp()
	let s:name = g:vimmake_path . '/readme.txt'
	exec 'FileSwitch vs '. fnameescape(s:name)
endfunc

function! menu#EmacsGdb()
	if has('win32') || has('win16') || has('win64') || has('win95')
		let name = expand('%:p:h') .'\' . expand('%:t:r') . '.exe'
	else
		let name = expand('%:p:h') .'/' . expand('%:t:r')
	endif
	if !executable(name)
		call asclib#errmsg('error: expect: '. name)
		return
	elseif !executable(asclib#setting#get('emacs', 'emacs'))
		call asclib#errmsg('error: not find emacs executable')
		return
	elseif !executable(asclib#setting#get('gdb', 'gdb'))
		call asclib#errmsg('error: not find gdb executable')
		return
	endif
	call asclib#utils#emacs_gdb(name)
endfunc

function! menu#ReadUrl()
	let t = expand('<cword>')
	echohl Type
	call inputsave()
	let t = input('Read URL from: ')
	call inputrestore()
	echohl None
	redraw | echo "" | redraw
	if t == ''
		return 0
	endif
	if executable('curl')
		exec '.-1r !curl -sL '.shellescape(t)
	elseif executable('wget')
		exec '.-1r !wget --no-check-certificate -qO- '.shellescape(t)
	else
		echo "require wget or curl"
	endif
endfunc


"----------------------------------------------------------------------
" menu initialize
"----------------------------------------------------------------------

let g:quickmenu_options = 'LH'

call quickmenu#current(0)
call quickmenu#reset()

call quickmenu#append('# Development', '')
call quickmenu#append('Execute', 'VimExecute run', 'run %{expand("%")}')
call quickmenu#append('GCC', 'VimBuild gcc', 'compile %{expand("%")}')
call quickmenu#append('Make', 'VimBuild make', 'make current project')
call quickmenu#append('Emake', 'VimBuild auto', 'emake build current project')
call quickmenu#append('Run', 'VimExecute auto', 'emake run project')
call quickmenu#append('Stop', 'VimStop', 'stop making or searching')

call quickmenu#append('# Find', '')
call quickmenu#append('Find word', 'call menu#FindInProject()', 'find (%{expand("<cword>")}) in current project')
call quickmenu#append('Tag view', 'call asclib#preview_tag(expand("<cword>"))', 'find (%{expand("<cword>")}) in ctags database')
call quickmenu#append('Tag update', 'call vimmake#update_tags("!", "ctags", ".tags")', 'reindex ctags database')
call quickmenu#append('Switch Header', 'call Open_HeaderFile(1)', 'switch header/source', 'c,cpp,objc,objcpp')

call quickmenu#append('Check: flake8', 'call asclib#lint_flake8("")', 'run flake8 in current document, [e to display error', 'python')
call quickmenu#append('Check: pylint', 'call asclib#lint_pylint("")', 'run pylint in current document, [e to display error', 'python')
call quickmenu#append('Check: cppcheck', 'call asclib#lint_cppcheck("")', 'run cppcheck, [e to display error', 'c,cpp,objc,objcpp')

call quickmenu#append('# SVN / GIT', '')
call quickmenu#append("view diff", 'call svnhelp#svn_diff("%")', 'show svn/git diff side by side, ]c, [c to jump between changes')
call quickmenu#append("show log", 'call svnhelp#svn_log("%")', 'show svn/git diff in quickfix window, F10 to close/open quickfix')
call quickmenu#append("file add", 'call svnhelp#svn_add("%")', 'add file to repository')

call quickmenu#append('# Utility', '')
call quickmenu#append('Compare file', 'call svnhelp#compare_ask_file()', 'use vertical diffsplit, compare current file to another (use filename)')
call quickmenu#append('Compare buffer', 'call svnhelp#compare_ask_buffer()', 'use vertical diffsplit, compare current file to another (use buffer id)')
call quickmenu#append('Paste mode %{&paste? "[x]" :"[ ]"}', 'call menu#TogglePaste()', 'set paste!')
call quickmenu#append('Ignore Case %{&ignorecase? "[x]" :"[ ]"}', 'set ignorecase!', 'set ignorecase!')
call quickmenu#append('DelimitMate %{get(b:, "delimitMate_enabled", 0)? "[x]":"[ ]"}', 'DelimitMateSwitch', 'switch DelimitMate')


if has('win32') || has('win64') || has('win16') || has('win95')
	call quickmenu#append('Open cmd', 'call menu#WinOpen("cmd")', 'Open cmd.exe in current file directory')
	call quickmenu#append('Open explorer', 'call menu#WinOpen("")', 'Open Windows Explorer in current file directory')
endif



"----------------------------------------------------------------------
" another menu
"----------------------------------------------------------------------

call quickmenu#current(1)
call quickmenu#reset()

call quickmenu#append('# GNU Global Find', '')
call quickmenu#append('Definition', 'call menu#Escope("g")', 'find (g): this definition')
call quickmenu#append('Symbol', 'call menu#Escope("s")', 'find (s): this symbol')
call quickmenu#append('Called by', 'call menu#Escope("d")', 'find (d): functions called by this')
call quickmenu#append('Functions calling', 'call menu#Escope("c")', 'find (c): functions calling this')
call quickmenu#append('Text string', 'call menu#Escope("t")', 'find (t): this text string')
call quickmenu#append('Egrep pattern', 'call menu#Escope("e")', 'find (e): this egrep pattern')
call quickmenu#append('Find file', 'call menu#Escope("f")', 'find (f): this file')
call quickmenu#append('Files including', 'call menu#Escope("i")', 'find (i): files #including this file')
" call quickmenu#append('Reset database', 'GscopeKill')
" call quickmenu#append('Reindex', 'Es! build gtags %')


if has('win32') || has('win64') || has('win16') || has('win95')
	call quickmenu#append('# Tortoise SVN / GIT', '')
	call quickmenu#append('Project update', 'call svnhelp#tp_update()', 'update current repository')
	call quickmenu#append('Project commit', 'call svnhelp#tp_commit()', 'commit this project')
	call quickmenu#append('Project log', 'call svnhelp#tp_log()', 'display project log')
	call quickmenu#append('Project diff', 'call svnhelp#tp_diff()', 'project diff')
	call quickmenu#append('File add', 'call svnhelp#tf_add()', 'file add')
	call quickmenu#append('File blame', 'call svnhelp#tf_blame()', 'file blame')
	call quickmenu#append('File commit', 'call svnhelp#tf_commit()', 'file commit')
	call quickmenu#append('File diff', 'call svnhelp#tf_diff()', 'file diff')
	call quickmenu#append('File revert', 'call svnhelp#tf_revert()', 'file revert')
	call quickmenu#append('File log', 'call svnhelp#tf_log()', 'file log')
endif

call quickmenu#append('# Tools', '')

call quickmenu#append('Trailing Space', 'call StripTrailingWhitespace()', 'Strip trailing whitespace')
call quickmenu#append('Update ModTime', 'call UpdateLastModified()', 'Update last modified time')
call quickmenu#append('Tool help', 'call menu#ToolHelp()', 'show the help of user tools')
call quickmenu#append('Signify refresh', 'SignifyRefresh', 'update signify')
call quickmenu#append('Calendar', 'Calendar', 'show Calendar')
call quickmenu#append('Paste mode line', 'PasteVimModeLine', 'paste vim mode line here')
call quickmenu#append('Dash Help', 'call menu#DashHelp()', 'open dash or zeal to view keywords in docsets')
call quickmenu#append('Emacs GDB', 'call menu#EmacsGdb()', 'debug with emacs gdb-mode', 'c,cpp,objc,objcpp')
call quickmenu#append('Read URL', 'call menu#ReadUrl()', 'load content from url')

if has('win32') || has('win64') || has('win16') || has('win95')
	let s:cmd = '!start /b cmd.exe /C start https://wakatime.com/dashboard'
	call quickmenu#append('WakaTime', 'silent! '.s:cmd, 'Goto WakaTime dashboard')
endif


" call quickmenu#append('GNU Global')


"----------------------------------------------------------------------
" Third menu
"----------------------------------------------------------------------
call quickmenu#current(2)
call quickmenu#reset()

call quickmenu#append('# Terminal', '')
call quickmenu#append('Open Terminal Below', 'belowright term ++rows=10', 'Open terminal below current window')
call quickmenu#append('Open Python Below', 'belowright term ++rows=10 python', 'Open python below current window')

call quickmenu#append('# Debug', '')


