"======================================================================
"
" commands.vim - 
"
" Created by skywind on 2021/12/22
" Last Modified: 2024/07/04 19:29
"
"======================================================================


"----------------------------------------------------------------------
" Follow switchbuf option to open a file
" usage: 
"     :FileSwitch abc.txt
"     :FileSwitch -switch=useopen,usetab,auto abc.txt
"     :FileSwitch -switch=useopen -mods=botright abc.txt
"----------------------------------------------------------------------
command! -nargs=+ -complete=file FileSwitch 
	\ call s:FileSwitch('<mods>', [<f-args>])
function! s:FileSwitch(mods, args)
	let args = deepcopy(a:args)
	if a:mods != ''
		let args = ['-mods=' . a:mods] + args
	endif
	call asclib#utils#file_switch(args)
endfunc


"----------------------------------------------------------------------
" Switch cpp/h file
"----------------------------------------------------------------------
command! -nargs=* -complete=customlist,module#alternative#complete
	\ SwitchHeader call module#alternative#switch('<mods>', [<f-args>])


"----------------------------------------------------------------------
" paste mode line
"----------------------------------------------------------------------
command! -nargs=0 PasteVimModeLine call s:PasteVimModeLine()
function! s:PasteVimModeLine()
	let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
		\ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
	if &commentstring != ""
		let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
	else
		let l:modeline = substitute(l:modeline, '^ ', '', 'g')
	endif
	let l:save = @0
	let @0 = l:modeline
	exec 'normal! "0P'
	let @0 = l:save
endfunc


"----------------------------------------------------------------------
" remove trailing white-spaces
"----------------------------------------------------------------------
command! -nargs=0 StripTrailingWhitespace call s:StripTrailingWhitespace()
function! s:StripTrailingWhitespace()
	let _s=@/
	let l = line(".")
	let c = col(".")
	" do the business:
	exec '%s/\r$\|\s\+$//e'
	" clean up: restore previous search history, and cursor position
	let @/=_s
	call cursor(l, c)
endfunc


"----------------------------------------------------------------------
" update last modified time
"----------------------------------------------------------------------
command! -nargs=0 UpdateLastModified call s:UpdateLastModified()
function! s:UpdateLastModified()
	" preparation: save last search, and cursor position.
	let _s=@/
	let l = line(".")
	let c = col(".")

	let n = min([10, line('$')]) " check head
	let timestamp = strftime('%Y/%m/%d %H:%M:%S') " time format
	let timestamp = substitute(timestamp, '%', '\%', 'g')
	let pat = substitute('Last Modified:\s*\zs.*\ze', '%', '\%', 'g')
	keepjumps silent execute '1,'.n.'s%^.*'.pat.'.*$%'.timestamp.'%e'

	" clean up: restore previous search history, and cursor position
	let @/=_s
	call cursor(l, c)
endfunc


"----------------------------------------------------------------------
" open terminal
"----------------------------------------------------------------------
command! -nargs=? OpenTerminal call s:OpenTerminal(<q-args>)
function! s:OpenTerminal(pos)
	let pos = asclib#string#strip(a:pos)
	let pos = (pos != '')? pos : 'TAB'
	let shell = get(g:, 'terminal_shell', split(&shell, ' ')[0])
	exec 'AsyncRun -mode=term -pos='. (pos) . ' -cwd=<root> ' . shell
endfunc


"----------------------------------------------------------------------
" break long lines to small lines of 76 characters.
"----------------------------------------------------------------------
command! -nargs=1 LineBreaker call s:LineBreaker(<q-args>)
function! s:LineBreaker(width)
	let width = &textwidth
	let p1 = &g:formatprg
	let p2 = &l:formatprg
	let &textwidth = str2nr(a:width)
	set formatprg=
	setlocal formatprg=
	exec 'normal ggVGgq'
	let &textwidth = width
	let &g:formatprg = p1
	let &l:formatprg = p2
endfunc


"----------------------------------------------------------------------
" OpenURL[!] [url]
" - open url in default browser (change this by g:browser_cmd)
" - when bang (!) is included, ignore g:browser_cmd
" - when url is omitted, use the current url under cursor
" - vim-plug format "Plug 'xxx'" can also be accepted.
"----------------------------------------------------------------------
command! -nargs=* -bang OpenURL call s:OpenURL(<q-args>, '<bang>')
function! s:OpenURL(url, bang)
	let url = a:url
	if url == ''
		let url = asclib#utils#current_url()
	endif
	if url != ''
		call asclib#utils#open_url(url, a:bang)
	else
		call asclib#common#errmsg('ERROR: URL is empty')
	endif
endfunc


"----------------------------------------------------------------------
" browse code in github or gitlab
"----------------------------------------------------------------------
command! -nargs=* -bang BrowseGit call s:BrowseGit(<q-args>, '<bang>')
function! s:BrowseGit(name, bang, ...)
	let name = asclib#string#strip(a:name)
	let raw = (a:0 > 0)? (a:1) : 0
	let url = asclib#utils#git_browse(name, raw)
	if url != ''
		call s:OpenURL(url, a:bang)
	endif
endfunc


"----------------------------------------------------------------------
" Insert Class Name
"----------------------------------------------------------------------
command! -nargs=0 -range CppClassInsert 
			\ call module#cpp#class_insert(<line1>, <line2>)


"----------------------------------------------------------------------
" expand brace
"----------------------------------------------------------------------
command! -nargs=0 -range CppBraceExpand
			\ call module#cpp#brace_expand(<line1>, <line2>)


"----------------------------------------------------------------------
" cd to file directory
"----------------------------------------------------------------------
command! -nargs=0 CdToFileDir call s:CdToFileDir()
function! s:CdToFileDir()
	if &buftype == '' && expand('%') != ''
		silent exec 'cd ' . fnameescape(expand('%:p:h'))
		exec 'pwd'
	endif
endfunc


"----------------------------------------------------------------------
" cd to project root
"----------------------------------------------------------------------
command! -nargs=0 CdToProjectRoot call s:CdToProjectRoot()
function! s:CdToProjectRoot()
	if &buftype == '' && expand('%') != ''
		let root = asclib#path#get_root(expand('%:p'))
		silent exec 'cd ' . fnameescape(root)
		exec 'pwd'
	endif
endfunc


"----------------------------------------------------------------------
" edit current snippet file
"----------------------------------------------------------------------
command! -nargs=? CodeSnipEdit call s:CodeSnipEdit(<q-args>)
function! s:CodeSnipEdit(args)
	let ft = ((a:args) == '')? &ft : (a:args)
	if ft == ''
		call asclib#core#errmsg('non-empty file type required')
		return 0
	elseif exists(':SnipMateLoadScope') == 2 && exists(':SnipMateEdit') == 2
		exec 'SnipMateEdit ' . ft
	elseif exists(':UltiSnipsEdit') == 2
		UltiSnipEdit
	else
		call module#snipmate#edit(ft)
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" expand snip
"----------------------------------------------------------------------
command! -nargs=1 CodeSnipExpand call s:CodeSnipExpand(<q-args>)
function! s:CodeSnipExpand(args)
	call module#snipmate#expand(a:args)
endfunc


"----------------------------------------------------------------------
" list loaded scripts
"----------------------------------------------------------------------
command! -nargs=0 ScriptNames call s:ScriptNames()
function! s:ScriptNames()
	redir => x
	silent scriptnames
	redir END
	tabnew
	let save = @0
	let @0 = x
	exec 'normal "0Pggdd'
	let @0 = save
	setlocal nomodified
endfunc



"----------------------------------------------------------------------
" sudo write
"----------------------------------------------------------------------
command! -nargs=0 -bang SudoWrite call s:SudoWrite('<bang>')
function! s:SudoWrite(bang) abort
	let t = expand('%')
	if !empty(&bt)
		echohl ErrorMsg
		echo "E382: Cannot write, 'buftype' option is set"
		echohl None
	elseif empty(t)
		echohl ErrorMsg
		echo 'E32: No file name'
		echohl None
	elseif !executable('sudo')
		echohl ErrorMsg
		echo 'Error: not find sudo executable'
		echohl None
	elseif executable('tee') == 0 && executable('busybox') == 0
		echohl ErrorMsg
		echo 'Error: not find tee/busybox executable'
		echohl None
	else
		let e = executable('tee')? 'tee' : 'busybox tee'
		exec printf('w%s !sudo %s %s > /dev/null', a:bang, e, shellescape(t))
		if !v:shell_error
			edit!
		endif
	endif
endfunc


"----------------------------------------------------------------------
" Help
"----------------------------------------------------------------------
command! -nargs=+ -complete=customlist,module#extension#help_complete
			\ Help call module#extension#help(<f-args>)


"----------------------------------------------------------------------
" open shell
"----------------------------------------------------------------------
command! -nargs=1 OpenShell call s:OpenShell(<f-args>)
function! s:OpenShell(what)
	let what = a:what
	let root = expand('%:p:h')
	if what == 'cmdclink' || what == 'clinkcmd'
		let what = filereadable('c:/drivers/clink/clink.cmd')? 'clink' : 'cmd'
	endif
	call asclib#path#push(root)
	if what == 'cmd'
		exec "silent !start cmd.exe"
	elseif what == 'clink'
		let cmd = 'silent AsyncRun -mode=term -pos=hide -cwd=$(VIM_FILEDIR) '
		let cmd .= " C:\\drivers\\clink\\clink.cmd"
		exec cmd
	else
		exec "silent !start /b cmd.exe /C start ."
	endif
	call asclib#path#pop()
endfunc


"----------------------------------------------------------------------
" toggle Reading Mode
"----------------------------------------------------------------------
command! -nargs=0 ToggleReadingMode call module#extension#toggle_reading_mode()


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
command! -nargs=0 CloseRightTabs call s:CloseRightTabs()
function! s:CloseRightTabs() abort
	let tid = tabpagenr()
	while 1
		let last = tabpagenr('$')
		if last == tid
			break
		endif
		exec printf('tabclose %d', last)
	endwhile
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
command! -nargs=0 CloseLeftTabs call s:CloseLeftTabs()
function! s:CloseLeftTabs()
	while tabpagenr() != 1
		exec 'tabclose 1'
	endwhile
endfunc


"----------------------------------------------------------------------
" http://www.drchip.org/astronaut/vim/index.html#Maps 
"----------------------------------------------------------------------
command! -nargs=0 DisplayHighlightGroup call s:DisplayHighlightGroup()
function! s:DisplayHighlightGroup() abort
	let h1 = synIDattr(synID(line("."), col("."),1), "name")
	let h2 = synIDattr(synID(line("."), col("."),0), "name")
	let h3 = synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name")
	echo printf('hi<%s> trans<%s> lo<%s>', h1, h2, h3)
endfunc


"----------------------------------------------------------------------
" Shougo: AddNumber
"----------------------------------------------------------------------
command! -range -nargs=1 AddNumbers
			\ call s:AddNumbers((<line2>-<line1>+1) * eval(<args>))
function! s:AddNumbers(num)
	let prev_line = getline('.')[: col('.')-1]
	let next_line = getline('.')[col('.') :]
	let prev_num = matchstr(prev_line, '\d\+$')
	if prev_num != ''
		let next_num = matchstr(next_line, '^\d\+')
		let new_line = prev_line[: -len(prev_num)-1] .
					\ printf('%0'.len(prev_num).'d',
					\    max([0, prev_num . next_num + a:num])) . 
					\    next_line[len(next_num):]
	else
		let new_line = prev_line . substitute(next_line, '\d\+',
					\ "\\=printf('%0'.len(submatch(0)).'d',
					\         max([0, submatch(0) + a:num]))", '')
	endif

	if getline('.') !=# new_line
		call setline('.', new_line)
	endif
endfunc



"----------------------------------------------------------------------
" DiffFile
"----------------------------------------------------------------------
command! -nargs=1 -complete=file DiffFile vertical diffsplit <args>
command! -nargs=0 Undiff setlocal nodiff noscrollbind wrap


"----------------------------------------------------------------------
" DiffOrig command
"----------------------------------------------------------------------
if !exists(":DiffOrig")
	command DiffOrig vert new | set bt=nofile | r ++edit # |
				\ 0d_ | diffthis | wincmd p | diffthis
endif


"----------------------------------------------------------------------
" JunkFile: Open junk file.
"----------------------------------------------------------------------
command! -nargs=0 JunkFile call s:JunkFile()
function! s:JunkFile()
	let junk_dir = asclib#setting#get('junk', '~/.vim/junk')
	let junk_dir = junk_dir . strftime('/%Y/%m')
	let real_dir = expand(junk_dir)
	if !isdirectory(real_dir)
		call mkdir(real_dir, 'p')
	endif
	let filename = junk_dir.strftime('/%Y-%m-%d-%H%M%S.')
	let filename = tr(filename, '\', '/')
	let filename = input('Junk Code: ', filename)
	if filename != ''
		execute 'edit ' . fnameescape(filename)
	endif
endfunc


"----------------------------------------------------------------------
" JunkList: open junk list
"----------------------------------------------------------------------
command! -nargs=0 JunkList call s:JunkList()
function! s:JunkList()
	let junk_dir = asclib#setting#get('junk', '~/.vim/junk')
	" let junk_dir = expand(junk_dir) . strftime('/%Y/%m')
	let junk_dir = tr(junk_dir, '\', '/')
	echo junk_dir
	exec "Leaderf file " . fnameescape(expand(junk_dir))
endfunc


"----------------------------------------------------------------------
" Log: log to file
"----------------------------------------------------------------------
command! -nargs=+ Log call s:Log(<q-args>)
function! s:Log(text)
	let text = substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
	if exists('*writefile') && text != ''
		let filename = get(g:, 'quicknote_file', '~/.vim/quicknote.md')
		let notehead = get(g:, 'quicknote_head', '- ')
		let notetime = strftime("[%Y-%m-%d %H:%M:%S] ")
		let realname = expand(filename)
		call writefile([notehead . notetime . text], realname, 'a')
		checktime
		echo notetime . text
	endif
endfunc


"----------------------------------------------------------------------
" EditRuntimeFile
"----------------------------------------------------------------------
command! -nargs=1 EditRuntimeFile call s:EditRuntimeFile(<q-args>)
function! s:EditRuntimeFile(fn) abort
	let fn = asclib#path#runtime(a:fn)
	let dir = asclib#path#dirname(fn)
	if !isdirectory(dir)
		echohl ErrorMsg
		echo "ERROR: directory does not exist: " . dir
		echohl None
	else
		exec 'FileSwitch -switch=useopen,usetab,auto ' . fnameescape(fn)
	endif
endfunc


"----------------------------------------------------------------------
" EditFileTypeScript
"----------------------------------------------------------------------
command! -nargs=? EditFileTypeScript call s:EditFileTypeScript(<q-args>)
function! s:EditFileTypeScript(ft)
	let ft = (a:ft == '')? (&ft) : (a:ft)
	call s:EditRuntimeFile('ftplugin/' . ft . '.vim')
endfunc


"----------------------------------------------------------------------
" update local helptags
"----------------------------------------------------------------------
command! -nargs=0 RtUpdateHelpTags call s:RtUpdateHelpTags()
function! s:RtUpdateHelpTags() abort
	let doc = asclib#path#runtime('doc')
	exec 'helptags ++t ' . fnameescape(doc)
endfunc


"----------------------------------------------------------------------
" display side by side diff in a new tabpage
" usage: DiffSplit <left_file> <right_file>
"----------------------------------------------------------------------
command! -nargs=+ -complete=file DiffSplit call s:DiffSplit(<f-args>)
function! s:DiffSplit(...) abort
	if a:0 != 2
		echohl ErrorMsg
		echom 'ERROR: Require two file names.'
		echohl None
	else
		exec 'tabe ' . fnameescape(a:1)
		exec 'rightbelow vert diffsplit ' . fnameescape(a:2)
		setlocal foldlevel=20
		exec 'wincmd p'
		setlocal foldlevel=20
		exec 'normal! gg]c'
	endif
endfunc


"----------------------------------------------------------------------
" Remove Italics: https://gist.github.com/mattn/3f43125df1020fada9b6
"----------------------------------------------------------------------
command! -nargs=0 DisableItalic call asclib#style#remove_style('italic')



"----------------------------------------------------------------------
" use gui colors
"----------------------------------------------------------------------
command! -nargs=0 ConvertGUIColor call module#colors#convert_gui_color()


"----------------------------------------------------------------------
" ModeSwitch
"----------------------------------------------------------------------
command! -nargs=? -complete=customlist,module#mode#complete
			\ ModeSwitch call module#mode#cmd(<bang>0, <q-args>)


"----------------------------------------------------------------------
" ModeList
"----------------------------------------------------------------------
command! -nargs=0 ModeList call s:ModeList()
function! s:ModeList()
	for n in module#mode#list()
		echo n
	endfor
endfunc


"----------------------------------------------------------------------
" ModeSelect: select mode
"----------------------------------------------------------------------
command! -nargs=0 ModeSelect call module#mode#select()



"----------------------------------------------------------------------
" toggle keymap
"----------------------------------------------------------------------
command! -nargs=0 ToggleJapaneseKeymap call s:ToggleJapaneseKeymap()
function! s:ToggleJapaneseKeymap()
	if &keymap == ''
		exec 'set keymap=kana'
		call asclib#common#echo('Title', 'Keymap: kana')
	else
		exec 'set keymap='
		call asclib#common#echo('Title', 'Keymap: none')
	endif
endfunction


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
command! -nargs=* -bang DumpArgs call s:DumpArgs('<bang>', <f-args>)

function! s:DumpArgs(bang, ...)
	echo printf('DumpArgs[%s]: %s', a:bang, a:000)
endfunc


"----------------------------------------------------------------------
" CondaActivate
"----------------------------------------------------------------------
command! -nargs=+ -complete=customlist,module#conda#complete
			\ CondaActivate call s:CondaActivate(<f-args>)

function! s:CondaActivate(name) abort
	let ret = module#conda#activate(a:name)
	if ret == 0
		call asclib#common#echo('Title', 'Conda: activate ' . a:name)
	endif
endfunc


"----------------------------------------------------------------------
" CondaDeactivate
"----------------------------------------------------------------------
command! -nargs=0 CondaDeactivate call s:CondaDeactivate()
function! s:CondaDeactivate() abort
	let name = module#conda#current()
	if name == ''
		call asclib#common#errmsg('Conda: no environment activated')
		return 0
	endif
	let ret = module#conda#deactivate()
	if ret == 0
		call asclib#common#echo('Title', 'Conda: deactivate ' . name)
	endif
	return 0
endfunc


