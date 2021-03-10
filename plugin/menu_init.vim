"======================================================================
"
" menu_init.vim -
"
" Created by skywind on 2019/12/26
" Last Modified: 2019/12/26 16:23:48
"
"======================================================================

if has('patch-8.1.2292') == 0 && exists('*nvim_open_win') == 0
	finish
endif

call quickui#menu#reset()

call quickui#menu#install("&File", [
			\ [ "&Open\t(:w)", 'call feedkeys(":tabe ")'],
			\ [ "&Save\t(:w)", 'write'],
			\ [ "--", ],
			\ [ "LeaderF &File", 'Leaderf file', 'Open file with leaderf'],
			\ [ "LeaderF &Mru", 'Leaderf mru --regexMode', 'Open recently accessed files'],
			\ [ "LeaderF &Buffer", 'Leaderf buffer', 'List current buffers in leaderf'],
			\ [ "--", ],
			\ [ "J&unk File", 'JunkFile', ''],
			\ [ "Junk L&ist", 'JunkList', ''],
			\ [ "--", ],
			\ [ "&Terminal Tab", 'OpenTerminal tab', 'Open internal terminal in a new tab'],
			\ [ "Terminal Spl&it", 'OpenTerminal right', 'Open internal terminal in a split'],
			\ [ "Open &URL", 'OpenURL', 'Open URL under cursor'],
			\ [ "Browse &Git", 'BrowseGit', 'Browse code in github'],
			\ ])

if has('win32') || has('win64') || has('win16')
	call quickui#menu#install('&File', [
				\ [ "Start &Cmd", 'silent !start /b cmd /C c:\drivers\clink\clink.cmd' ],
				\ [ "Start &PowerShell", 'silent !start powershell.exe' ],
				\ [ "Open &Explore", 'call Show_Explore()' ],
				\ ])
endif

call quickui#menu#install("&File", [
			\ [ "--", ],
			\ [ "E&xit", 'qa' ],
			\ ])

call quickui#menu#install("&Edit", [
			\ ['Copyright &Header', 'call feedkeys("\<esc> ec")', 'Insert copyright information at the beginning'],
			\ ['&Trailing Space', 'call StripTrailingWhitespace()', ''],
			\ ['Update &ModTime', 'call UpdateLastModified()', ''],
			\ ['&Paste Mode Line', 'PasteVimModeLine', ''],
			\ ['Format J&son', '%!python -m json.tool', ''],
			\ ['--'],
			\ ['&Align Table', 'Tabularize /|', ''],
			\ ['Align &Cheatsheet', 'MyCheatSheetAlign', ''],
			\ ['&Break long line', 'call MenuHelp_SplitLine()', ''],
			\ ])

call quickui#menu#install('&Symbol', [
			\ [ "&Grep Word\t(In Project)", 'call MenuHelp_GrepCode()', 'Grep keyword in current project' ],
			\ [ "--", ],
			\ [ "Find &Definition\t(GNU Global)", 'call MenuHelp_Gscope("g")', 'GNU Global search g'],
			\ [ "Find &Symbol\t(GNU Global)", 'call MenuHelp_Gscope("s")', 'GNU Gloal search s'],
			\ [ "Find &Called by\t(GNU Global)", 'call MenuHelp_Gscope("d")', 'GNU Global search d'],
			\ [ "Find C&alling\t(GNU Global)", 'call MenuHelp_Gscope("c")', 'GNU Global search c'],
			\ [ "Find &From Ctags\t(GNU Global)", 'call MenuHelp_Gscope("z")', 'GNU Global search c'],
			\ [ "--", ],
			\ [ "Goto D&efinition\t(YCM)", 'YcmCompleter GoToDefinitionElseDeclaration'],
			\ [ "Goto &References\t(YCM)", 'YcmCompleter GoToReferences'],
			\ [ "Get D&oc\t(YCM)", 'YcmCompleter GetDoc'],
			\ [ "Get &Type\t(YCM)", 'YcmCompleter GetTypeImprecise'],
			\ ])

call quickui#menu#install('&Move', [
			\ ["EasyMotion &Search\t<tab>m", 'call MenuHelp_EasyMotion("s")', 'easymotion-s'],
			\ ["EasyMotion &Word\t<tab>n", 'call MenuHelp_EasyMotion("bd-w")', 'easymotion-bd-w'],
			\ [ "--" ],
			\ ["Quickfix &First\t:cfirst", 'cfirst', 'quickfix cursor rewind'],
			\ ["Quickfix L&ast\t:clast", 'clast', 'quickfix cursor to the end'],
			\ ["Quickfix &Next\t:cnext", 'cnext', 'cursor next'],
			\ ["Quickfix &Previous\t:cprev", 'cprev', 'quickfix cursor previous'],
			\ ])

call quickui#menu#install("&Build", [
			\ ["File &Execute\tF5", 'AsyncTask file-run'],
			\ ["File &Compile\tF9", 'AsyncTask file-build'],
			\ ["File E&make\tF7", 'AsyncTask emake'],
			\ ["File &Start\tF8", 'AsyncTask emake-exe'],
			\ ['--', ''],
			\ ["&Project Build\tShift+F9", 'AsyncTask project-build'],
			\ ["Project &Run\tShift+F5", 'AsyncTask project-run'],
			\ ["Project &Test\tShift+F6", 'AsyncTask project-test'],
			\ ["Project &Init\tShift+F7", 'AsyncTask project-init'],
			\ ['--', ''],
			\ ["T&ask List\tCtrl+F10", 'call MenuHelp_TaskList()'],
			\ ['E&dit Task', 'AsyncTask -e'],
			\ ['Edit &Global Task', 'AsyncTask -E'],
			\ ['&Stop Building', 'AsyncStop'],
			\ ])

call quickui#menu#install("&Git", [
			\ ['&View Diff', 'call svnhelp#svn_diff("%")'],
			\ ['&Show Log', 'call svnhelp#svn_log("%")'],
			\ ['File &Add', 'call svnhelp#svn_add("%")'],
			\ ['-'],
			\ ['&Fugitive Status', 'Gstatus'],
			\ ['Fugitive P&ush', 'Gpush'],
			\ ['Fugitive Fe&tch', 'Gfetch'],
			\ ['Fugitive R&ead', 'Gread'],
			\ ])


if has('win32') || has('win64') || has('win16') || has('win95')
	call quickui#menu#install("&Git", [
				\ ['--',''],
				\ ["Project &Update\t(Tortoise)", 'call svnhelp#tp_update()', 'TortoiseGit / TortoiseSvn'],
				\ ["Project &Commit\t(Tortoise)", 'call svnhelp#tp_commit()', 'TortoiseGit / TortoiseSvn'],
				\ ["Project L&og\t(Tortoise)", 'call svnhelp#tp_log()',  'TortoiseGit / TortoiseSvn'],
				\ ["Project &Diff\t(Tortoise)", 'call svnhelp#tp_diff()', 'TortoiseGit / TortoiseSvn'],
				\ ["Project &Push\t(Tortoise)", 'call svnhelp#tp_push()', 'TortoiseGit'],
				\ ["Project S&ync\t(Tortoise)", 'call svnhelp#tp_sync()', 'TortoiseGit'],
				\ ['--',''],
				\ ["File &Add\t(Tortoise)", 'call svnhelp#tf_add()', 'TortoiseGit / TortoiseSvn'],
				\ ["File &Blame\t(Tortoise)", 'call svnhelp#tf_blame()', 'TortoiseGit / TortoiseSvn'],
				\ ["File Co&mmit\t(Tortoise)", 'call svnhelp#tf_commit()', 'TortoiseGit / TortoiseSvn'],
				\ ["File D&iff\t(Tortoise)", 'call svnhelp#tf_diff()', 'TortoiseGit / TortoiseSvn'],
				\ ["File &Revert\t(Tortoise)", 'call svnhelp#tf_revert()', 'TortoiseGit / TortoiseSvn'],
				\ ["File Lo&g\t(Tortoise)", 'call svnhelp#tf_log()', 'TortoiseGit / TortoiseSvn'],
				\ ])
endif

call quickui#menu#install("&C/C++", [
			\ ["&Switch Header/Source\t<spc>fw", "call Open_HeaderFile(-1)"],
			\ ["S&plit Header/Source\t<spc>fw", "call Open_HeaderFile(1)"],
			\ ])

call quickui#menu#install('&Tools', [
			\ ['Compare &History', 'call svnhelp#compare_ask_file()', ''],
			\ ['&Compare Buffer', 'call svnhelp#compare_ask_buffer()', ''],
			\ ['--',''],
			\ ['List &Buffer', 'call quickui#tools#list_buffer("FileSwitch tabe")', ],
			\ ['List &Function', 'call quickui#tools#list_function()', ],
			\ ['Display &Messages', 'call quickui#tools#display_messages()', ],
			\ ['--',''],
			\ ["&DelimitMate %{get(b:, 'delimitMate_enabled', 0)? 'Disable':'Enable'}", 'DelimitMateSwitch'],
			\ ['Read &URL', 'call menu#ReadUrl()', 'load content from url into current buffer'],
			\ ['&Spell %{&spell? "Disable":"Enable"}', 'set spell!', 'Toggle spell check %{&spell? "off" : "on"}'],
			\ ['&Profile Start', 'call MonitorInit()', ''],
			\ ['Profile S&top', 'call MonitorExit()', ''],
			\ ["Relati&ve number %{&relativenumber? 'OFF':'ON'}", 'set relativenumber!'],
			\ ["Proxy &Enable", 'call MenuHelp_Proxy(1)', 'setup http_proxy/https_proxy/all_proxy'],
			\ ["Proxy D&isable", 'call MenuHelp_Proxy(0)', 'clear http_proxy/https_proxy/all_proxy'],
			\ ])

call quickui#menu#install('&Plugin', [
			\ ["&NERDTree\t<space>tt", 'exec "NERDTreeToggle " . fnameescape(asclib#path#get_root("%"))', 'toggle nerdtree'],
			\ ["NERDTree &Focus\t<space>to", 'NERDTreeFocus'],
			\ ['&Tagbar', '', 'toggle tagbar'],
			\ ["&Choose Window/Tab\tAlt+e", "ChooseWin", "fast switch win/tab with vim-choosewin"],
			\ ["-"],
			\ ["&Browse in github\trhubarb", "Gbrowse", "using tpope's rhubarb to open browse and view the file"],
			\ ["&Startify", "Startify", "using tpope's rhubarb to open browse and view the file"],
			\ ["&Gist", "Gist", "open gist with mattn/gist-vim"],
			\ ["&Edit Note", "Note", "edit note with vim-notes"],
			\ ["&Display Calendar", "Calendar", "display a calender"],
			\ ['Toggle &Vista', 'Vista!!', ''],
			\ ["-"],
			\ ["Plugin &List", "PlugList", "Update list"],
			\ ["Plugin &Update", "PlugUpdate", "Update plugin"],
			\ ])

call quickui#menu#install('Help (&?)', [
			\ ["&Index", 'tab help index', ''],
			\ ['Ti&ps', 'tab help tips', ''],
			\ ['--',''],
			\ ["&Tutorial", 'tab help tutor', ''],
			\ ['&Quick Reference', 'tab help quickref', ''],
			\ ['&Summary', 'tab help summary', ''],
			\ ['--',''],
			\ ['&Vim Script', 'tab help eval', ''],
			\ ['&Function List', 'tab help function-list', ''],
			\ ['&Dash Help', 'call asclib#utils#dash_ft(&ft, expand("<cword>"))'],
			\ ], 10000)

" let g:quickui_show_tip = 1


"----------------------------------------------------------------------
" context menu
"----------------------------------------------------------------------
let g:context_menu_k = [
			\ ["&Peek Definition\tAlt+;", 'call quickui#tools#preview_tag("")'],
			\ ["S&earch in Project\t\\cx", 'exec "silent! GrepCode! " . expand("<cword>")'],
			\ [ "--", ],
			\ [ "Find &Definition\t\\cg", 'call MenuHelp_Fscope("g")', 'GNU Global search g'],
			\ [ "Find &Symbol\t\\cs", 'call MenuHelp_Fscope("s")', 'GNU Gloal search s'],
			\ [ "Find &Called by\t\\cd", 'call MenuHelp_Fscope("d")', 'GNU Global search d'],
			\ [ "Find C&alling\t\\cc", 'call MenuHelp_Fscope("c")', 'GNU Global search c'],
			\ [ "Find &From Ctags\t\\cz", 'call MenuHelp_Fscope("z")', 'GNU Global search c'],
			\ [ "--", ],
			\ [ "Goto D&efinition\t(YCM)", 'YcmCompleter GoToDefinitionElseDeclaration'],
			\ [ "Goto &References\t(YCM)", 'YcmCompleter GoToReferences'],
			\ [ "Cursor Ho&ver\t(YCM)", 'exec "normal \<plug>(YCMHover)"'],
			\ [ "Get D&oc\t(YCM)", 'YcmCompleter GetDoc'],
			\ [ "Get &Type\t(YCM)", 'YcmCompleter GetTypeImprecise'],
			\ [ "--", ],
			\ ['Dash &Help', 'call asclib#utils#dash_ft(&ft, expand("<cword>"))'],
			\ ['Cpp&man', 'exec "Cppman " . expand("<cword>")', '', "c,cpp"],
			\ ['P&ython Doc', 'call quickui#tools#python_help("")', '', 'python'],
			\ ["S&witch Header\t<SPC>fw", 'SwitchHeaderEdit', '', "c,cpp"],
			\ ["Display Highlight", 'call feedkeys(":hi \<c-r>\<c-w>\<cr>")', '', 'vim'],
			\ ]

" Keyword

"----------------------------------------------------------------------
" hotkey
"----------------------------------------------------------------------
nnoremap <silent><space><space> :call quickui#menu#open()<cr>

nnoremap <silent>K :call quickui#tools#clever_context('k', g:context_menu_k, {})<cr>

if has('gui_running') || has('nvim')
	noremap <c-f10> :call MenuHelp_TaskList()<cr>
endif



"----------------------------------------------------------------------
" Help Content
"----------------------------------------------------------------------
let g:help_content_win32 = [
			\ [ 'Win32 Help', 'd:/dev/help/win32.hlp'],
			\ [ 'MSDN of VC6', 'd:/dev/help/chm/vc.chm'],
			\ [ 'Python2 Help', 'd:/dev/help/chm/python2713.chm'],
			\ [ 'Python3 Help', 'd:/dev/help/chm/python382.chm'],
			\ [ 'DirectX 9c', 'd:/dev/help/chm/DirectX9_c.chm'],
			\ ]

if has('win32') || has('win64') || has('win16') || has('winxp')
	call quickui#menu#install('Help (&?)', [
				\ ['-'],
				\ ['&Content Win32', 'call MenuHelp_HelpList("h", g:help_content_win32)', ''],
				\ ])
endif


"----------------------------------------------------------------------
" fugitive 
"----------------------------------------------------------------------
let g:context_menu_git = [
			\ ["&Stage (add)\ts", 'exec "normal s"' ],
			\ ["&Unstage (reset)\tu", 'exec "normal u"' ],
			\ ["&Toggle stage/unstage\t-", 'exec "normal -"' ],
			\ ["Unstage &Everything\tU", 'exec "normal U"' ],
			\ ["D&iscard change\tX", 'exec "normal X"' ],
			\ ["--"],
			\ ["Inline &Diff\t=", 'exec "normal ="' ],
			\ ["Diff S&plit\tdd", 'exec "normal dd"' ],
			\ ["Diff &Horizontal\tdh", 'exec "normal dh"' ],
			\ ["Diff &Vertical\tdv", 'exec "normal dv"' ],
			\ ["--"],
			\ ["&Open File\t<CR>", 'exec "normal \<cr>"' ],
			\ ["Open in New Split\to", 'exec "normal o"' ],
			\ ["Open in New Vsplit\tgO", 'exec "normal gO"' ],
			\ ["Open in New Tab\tO", 'exec "normal O"' ],
			\ ["Open in &Preview\tp", 'exec "normal p"' ],
			\ ["--"],
			\ ["&Commit\tcc", 'exec "normal cc"' ],
			\ ]

function! s:setup_fugitive()
	nnoremap <silent><buffer>K :call quickui#tools#clever_context('g', g:context_menu_git, {})<cr>
endfunc


"----------------------------------------------------------------------
" events
"----------------------------------------------------------------------
augroup MenuEvents
	au!
	au FileType fugitive call s:setup_fugitive()
augroup END



