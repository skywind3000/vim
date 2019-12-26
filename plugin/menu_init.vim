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
			\ [ "LeaderF &File", 'Leaderf file'],
			\ [ "LeaderF &Mru", 'Leaderf mru --regexMode'],
			\ [ "LeaderF &Buffer", 'Leaderf buffer'],
			\ [ "--", ],
			\ [ "&Save\t(:w)", 'write'],
			\ ])

call quickui#menu#install("&Build", [
			\ ['&Compile File', 'VimBuild gcc'],
			\ ['E&xecute File', 'VimExecute Run'],
			\ ['--', ''],
			\ ['Project &Make', 'VimBuild make'],
			\ ['Project &EMake', 'VimBuild auto'],
			\ ['Project &Run', 'VimExecute auto'],
			\ ['--', ''],
			\ ['&Stop Build', 'VimStop'],
			\ ])

call quickui#menu#install('&Tags', [
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



"----------------------------------------------------------------------
" hotkey
"----------------------------------------------------------------------
nnoremap <silent><space><space> :call quickui#menu#open()<cr>


