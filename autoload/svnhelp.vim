
"----------------------------------------------------------------------
" internal definition
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')

function! svnhelp#errmsg(msg)
	redraw
	echohl ErrorMsg
	echom a:msg
	echohl NONE
endfunc


"----------------------------------------------------------------------
" svn main
"----------------------------------------------------------------------
function! svnhelp#svn(command)
	let hr = asclib#core#system('svn '. a:command)
	let s:shell_error = g:asclib#core#shell_error
	return hr
endfunc

function! svnhelp#git(command)
	let hr = asclib#core#system('git '. a:command)
	let s:shell_error = g:asclib#core#shell_error
	return hr
endfunc


"----------------------------------------------------------------------
" returns none(0), svn(1), git(2)
"----------------------------------------------------------------------
function! svnhelp#svn_or_git(target)
	let root = asyncrun#get_root(a:target, ['.svn', '.git'])
	if root == ''
		return 0
	endif
	if isdirectory(asclib#path#join(root, '.svn'))
		return 1
	elseif isdirectory(asclib#path#join(root, '.git'))
		return 2
	endif
	return 0
endfunc

function! svnhelp#svn_cat(target, revision)
	let cmd = 'cat '.shellescape(a:target)
	if a:revision != '' && a:revision != '0' && a:revision != 'HEAD'
		let cmd .= '@'.a:revision
	endif
	let name = tempname()
	let cmd .= ' > '.shellescape(name)
	call svnhelp#svn(cmd)
	if s:shell_error == 0
		return name
	endif
	if filereadable(name)
		silent! call delete(name)
	endif
	return ''
endfunc

function! svnhelp#git_name(target, revision)
	let filename = fnamemodify(expand(a:target), ':p')
	let filedir = fnamemodify(filename, ':h')
	let cmd = 'ls-tree --full-name --name-only '.a:revision
	let cmd.= ' '.shellescape(filename)
	call asclib#path#push_dir(filedir)
	let hr = svnhelp#git(cmd)
	call asclib#path#pop_dir()
	if s:shell_error
		return ''
	endif
	return split(hr, "\n", 1)[0]
endfunc

function! svnhelp#git_cat(target, revision)
	let revision = (a:revision == '')? 'HEAD' : a:revision
	let name = svnhelp#git_name(a:target, revision)
	if name == ''
		return ''
	endif
	let tmp = tempname()
	let cmd = 'show '.revision.':'.shellescape(name) 
	let cmd.= ' > '. shellescape(tmp)
	let filename = fnamemodify(expand(a:target), ':p')
	let filedir = fnamemodify(filename, ':h')
	call asclib#path#push_dir(filedir)
	call svnhelp#git(cmd)
	call asclib#path#pop_dir()
	if s:shell_error == 0
		return tmp
	endif
	if filereadable(tmp)
		silent! call delete(tmp)
	endif
	return ''
endfunc

function! svnhelp#diff_exit()
	if &cursorbind && exists('w:svnhelp_bid')
		let bid = w:svnhelp_bid
		unlet w:svnhelp_bid
		setlocal nocursorbind
		exec "bdelete ".bid
		diffoff!
		return 1
	endif
	return 0
endfunc

function! svnhelp#svn_diff(filename)
	if svnhelp#diff_exit()
		return
	endif
	let filename = expand(a:filename)
	let mode = svnhelp#svn_or_git(a:filename)
	if mode == 0
		call svnhelp#errmsg('not a svn/git working copy')
		return
	endif
	if mode == 1
		let hr = svnhelp#svn_cat(filename, '')
	else
		let hr = svnhelp#git_cat(filename, '')
	endif
	if hr == ''
		if mode == 1
			call svnhelp#errmsg('can not proceed svn diff')
		else
			call svnhelp#errmsg('can not proceed git show')
		endif
		return 
	endif
	let saveft = &ft
	let oldbid = bufnr('%')
	exec 'leftabove vert diffsplit '.fnameescape(hr)
	setlocal foldlevel=20
	let bid = bufnr('%')
	if &ft == '' && bid != oldbid
		let &l:filetype = saveft
	endif
	wincmd p
	let w:svnhelp_bid = bid
	setlocal foldlevel=20
	exec "normal gg]c"
	call LogWrite('[svn] diff: '.expand('%'))
endfunc


function! svnhelp#svn_log(filename)
	let mode = svnhelp#svn_or_git(a:filename)
	let name = fnamemodify(expand(a:filename), ':p')
	let home = fnameescape(fnamemodify(name, ':h'))
	let name = shellescape(name)
	if mode == 0
		call svnhelp#errmsg('not a svn/git repository')
		return
	elseif mode == 1
		exec 'AsyncRun! -raw svn log '.name
	else
		exec 'AsyncRun! -raw -cwd='.home.' git log '.name
	endif
endfunc

function! svnhelp#svn_add(filename)
	let mode = svnhelp#svn_or_git(a:filename)
	let name = fnamemodify(expand(a:filename), ':p')
	let home = fnameescape(fnamemodify(name, ':h'))
	let name = shellescape(name)
	if mode == 0
		call svnhelp#errmsg('not a svn/git repository')
		return
	elseif mode == 1
		exec 'AsyncRun! -raw svn add '.name
	else
		exec 'AsyncRun! -raw -cwd='.home.' git add '.name
	endif
endfunc


"----------------------------------------------------------------------
" diff current file on the left
"----------------------------------------------------------------------
function! svnhelp#compare_current(filename)
	if svnhelp#diff_exit()
		return
	endif
	let hr = expand(a:filename)
	exec 'leftabove vert diffsplit '.fnameescape(hr)
	setlocal foldlevel=20
	let bid = bufnr('%')
	wincmd p
	let w:svnhelp_bid = bid
	setlocal foldlevel=20
	exec "normal gg]c"
endfunc

function! svnhelp#compare_ask_file()
	if svnhelp#diff_exit()
		return
	endif
	let filename = input('Enter filename to compare: ', '', 'file')
	if filename == ''
		redraw
		return
	endif
	if !filereadable(filename)
		redraw
		call svnhelp#errmsg('can not open: '. filename)
		return
	endif
	call svnhelp#compare_current(filename)
endfunc


function! svnhelp#compare_ask_buffer() abort
	if svnhelp#diff_exit()
		return
	endif
	let bid = input('Enter buffer id to compare: ', '', 'buffer')
	let nid = str2nr(bid)
	let filename = ''
	if bid == ''
		return
	endif
	if nid > 0
		let filename = bufname(nid)
	endif
	if filename == ''
		let filename = bufname(bid)
	endif
	if filename == ''
		redraw
		call svnhelp#errmsg('invalid buffer name: '.bid)
		return
	endif
	if !filereadable(filename)
		redraw
		call svnhelp#errmsg('invalid file name: '.filename)
		return
	endif
	call svnhelp#compare_current(filename)
endfunc


"----------------------------------------------------------------------
" tsvn / tgit
"----------------------------------------------------------------------

function! svnhelp#tsvn(parameters) abort
	if s:windows == 0
		call svnhelp#errmsg('must run on windows')
		return
	endif
	if !executable('TortoiseProc.exe')
		call svnhelp#errmsg('not find TortoiseProc.exe')
		return
	endif
	silent exec '!start /b TortoiseProc.exe '.a:parameters
endfunc


function! svnhelp#tgit(parameters) abort
	if s:windows == 0
		call svnhelp#errmsg('must run on windows')
		return
	endif
	if !executable('TortoiseGitProc.exe')
		call svnhelp#errmsg('not find TortoiseGitProc.exe')
		return
	endif
	silent exec '!start /b TortoiseGitProc.exe '.a:parameters
endfunc


function! svnhelp#tinfo() abort
	let info = {}
	let info.mode = 0
	let root = asyncrun#get_root('%', ['.svn', '.git'])
	let info.root = root
	let info.filename = expand('%:t')
	let info.filedir = expand('%:p:h')
	let info.filepath = expand('%:p')
	let savecwd = getcwd()
	if root == ''
		return info
	endif
	call asclib#path#push_dir(root)
	let info.filerel = expand('%')
	call asclib#path#pop_dir()
	let info.filerel = substitute(info.filerel, '\\', '/', 'g')
	if isdirectory(asclib#path#join(root, '.svn'))
		let info.mode = 1
	elseif isdirectory(asclib#path#join(root, '.git'))
		let info.mode = 2
	elseif filereadable(asclib#path#join(root, '.git'))
		let info.mode = 2
	else
		return info
	endif
	return info
endfunc


"----------------------------------------------------------------------
" project
"----------------------------------------------------------------------

function! svnhelp#tp_update() abort
	let info = svnhelp#tinfo()
	if info.mode == 0
		call svnhelp#errmsg('not in a git/svn repository')
		return 0
	endif
	if info.mode == 1
		call svnhelp#tsvn('/command:update /path:'.shellescape(info.root))
	else
		call svnhelp#tgit('/command:pull /path:'.shellescape(info.root))
	endif
endfunc

function! svnhelp#tp_commit() abort
	let info = svnhelp#tinfo()
	if info.mode == 0
		call svnhelp#errmsg('not in a git/svn repository')
		return 0
	endif
	if info.mode == 1
		call svnhelp#tsvn('/command:commit /path:'.shellescape(info.root))
	else
		call svnhelp#tgit('/command:commit /path:'.shellescape(info.root))
	endif
endfunc

function! svnhelp#tp_log() abort
	let info = svnhelp#tinfo()
	if info.mode == 0
		call svnhelp#errmsg('not in a git/svn repository')
		return 0
	endif
	if info.mode == 1
		call svnhelp#tsvn('/command:log /path:'.shellescape(info.root))
	else
		call svnhelp#tgit('/command:log /path:'.shellescape(info.root))
	endif
endfunc


function! svnhelp#tp_diff() abort
	let info = svnhelp#tinfo()
	if info.mode == 0
		call svnhelp#errmsg('not in a git/svn repository')
		return 0
	endif
	if info.mode == 1
		call svnhelp#tsvn('/command:diff /path:'.shellescape(info.root))
	else
		call svnhelp#tgit('/command:diff /path:'.shellescape(info.root))
	endif
endfunc

function! svnhelp#tp_push() abort
	let info = svnhelp#tinfo()
	if info.mode == 0
		call svnhelp#errmsg('not in a git repository')
		return 0
	endif
	if info.mode == 1
		call svnhelp#errmsg('not in a git repository')
	else
		call svnhelp#tgit('/command:push /path:'.shellescape(info.root))
	endif
endfunc

function! svnhelp#tp_sync() abort
	let info = svnhelp#tinfo()
	if info.mode == 0
		call svnhelp#errmsg('not in a git repository')
		return 0
	endif
	if info.mode == 1
		call svnhelp#errmsg('not in a git repository')
	else
		call svnhelp#tgit('/command:sync /path:'.shellescape(info.root))
	endif
endfunc


"----------------------------------------------------------------------
" file 
"----------------------------------------------------------------------

function! svnhelp#tf_command(cmd) abort
	let info = svnhelp#tinfo()
	if info.mode == 0
		call svnhelp#errmsg('not in a git/svn repository')
		return 0
	endif
	if info.mode == 1
		call svnhelp#tsvn('/command:'.a:cmd.' /path:'.shellescape(info.filepath))
	else
		call svnhelp#tgit('/command:'.a:cmd.' /path:'.shellescape(info.filepath))
	endif
endfunc

function! svnhelp#tf_diff() abort
	call svnhelp#tf_command('diff')
endfunc

function! svnhelp#tf_log() abort
	call svnhelp#tf_command('log')
endfunc

function! svnhelp#tf_commit() abort
	call svnhelp#tf_command('commit')
endfunc

function! svnhelp#tf_blame() abort
	call svnhelp#tf_command('blame')
endfunc

function! svnhelp#tf_add() abort
	call svnhelp#tf_command('add')
endfunc

function! svnhelp#tf_revert() abort
	call svnhelp#tf_command('revert')
endfunc


