"======================================================================
"
" menu_init.vim - 
"
" Created by skywind on 2019/12/26
" Last Modified: 2019/12/26 16:23:48
"
"======================================================================

if has('patch-8.2.1') == 0 || has('nvim')
	finish
endif

call quickui#menu#reset()

call quickui#menu#install("&File", [
			\ [ "LeaderF &File", 'Leaderf file', 'help1'],
			\ [ "LeaderF &Mru", 'Leaderf mru --regexMode', 'help2'],
			\ [ "LeaderF &Buffer", 'Leaderf buffer'],
			\ [ "--", ],
			\ [ "&Save\t(:w)", 'write'],
			\ ])

call quickui#menu#install("&Build", [
			\ ["&Compile File\tF9", 'VimBuild gcc'],
			\ ["E&xecute File\tF5", 'VimExecute Run'],
			\ ['--', ''],
			\ ['Project &Make', 'VimBuild make'],
			\ ["Project &EMake\tF7", 'VimBuild auto'],
			\ ['Project &Run', 'VimExecute auto'],
			\ ['--', ''],
			\ ['&Stop Build', 'VimStop'],
			\ ])

call quickui#menu#install('&Symbol', [
			\ [ "&Grep Word\t(In Project)", 'call menu#FindInProject()' ],
			\ [ "--", '' ],
			\ [ "Find &Definition\t(GNU Global)", 'call menu#Escope("g")'],
			\ [ "Find &Symbol\t(GNU Global)", 'call menu#Escope("s")'],
			\ [ "Find &Called by\t(GNU Global)", 'call menu#Escope("d")'],
			\ [ "Find C&alling\t(GNU Global)", 'call menu#Escope("c")' ],
			\ ])

call quickui#menu#install("&Git", [
			\ ['&View Diff', 'call svnhelp#svn_diff("%")'],
			\ ['&Show Log', 'call svnhelp#svn_log("%")'],
			\ ['File &Add', 'call svnhelp#svn_add("%")'],
			\ ])


if has('win32') || has('win64') || has('win16') || has('win95')
	call quickui#menu#install("&Git", [
				\ ['--',''],
				\ ["Project &Update\t(Tortoise)", 'call svnhelp#tp_update()'],
				\ ["Project &Commit\t(Tortoise)", 'call svnhelp#tp_commit()'],
				\ ["Project L&og\t(Tortoise)", 'call svnhelp#tp_log()'],
				\ ["Project &Diff\t(Tortoise)", 'call svnhelp#tp_diff()'],
				\ ['--',''],
				\ ["File &Add\t(Tortoise)", 'call svnhelp#tf_add()'],
				\ ["File &Blame\t(Tortoise)", 'call svnhelp#tf_blame()'],
				\ ["File Co&mmit\t(Tortoise)", 'call svnhelp#tf_commit()'],
				\ ["File D&iff\t(Tortoise)", 'call svnhelp#tf_diff()'],
				\ ["File &Revert\t(Tortoise)", 'call svnhelp#tf_revert()'],
				\ ["File Lo&g\t(Tortoise)", 'call svnhelp#tf_log()'],
				\ ])
endif

call quickui#menu#install('&Tools', [
			\ ['&Trailing Space', 'call StripTrailingWhitespace()', ''],
			\ ['&Update ModTime', 'call UpdateLastModified()', ''],
			\ ['&Paste Mode Line', 'call PasteVimModeLine', ''],
			\ ['--',''],
			\ ['Compare &File', 'call svnhelp#compare_ask_file()', ''],
			\ ['Compare &Buffer', 'call svnhelp#compare_ask_buffer()', ''],
			\ ['--',''],
			\ ["&DelimitMate %{get(b:, 'delimitMate_enabled', 0)? 'Disable':'Enable'}", 'DelimitMateSwitch'],
			\ ['Read &URL', 'call menu#ReadUrl()', ''],
			\ ])

call quickui#menu#install('H&elp', [
			\ ["&Cheatsheet", 'help index', ''],
			\ ['--',''],
			\ ["&Tutorial", 'help tutor', ''],
			\ ['&Quick Reference', 'help quickref', ''],
			\ ['&Summary', 'help summary', ''],
			\ ['--',''],
			\ ['&Vim Script', 'help eval', ''],
			\ ['&Function List', 'help function-list', ''],
			\ ])


"----------------------------------------------------------------------
" hotkey
"----------------------------------------------------------------------
nnoremap <silent><space><space> :call quickui#menu#open()<cr>


