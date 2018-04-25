"======================================================================
"
" asclib.vim - autoload methods
"
" Created by skywind on 2016/10/28
" Last change: 2016/10/28 00:38:10
"
"======================================================================


"----------------------------------------------------------------------
" window basic
"----------------------------------------------------------------------

" echo error message
function! asclib#errmsg(msg)
	redraw | echo '' | redraw
	echohl ErrorMsg
	echom a:msg
	echohl NONE
endfunc

" echo cmdline message
function! asclib#cmdmsg(content, highlight)
	let saveshow = &showmode
	set noshowmode
    let wincols = &columns
    let statusline = (&laststatus==1 && winnr('$')>1) || (&laststatus==2)
    let reqspaces_lastline = (statusline || !&ruler) ? 12 : 29
    let width = len(a:content)
    let limit = wincols - reqspaces_lastline
	let l:content = a:content
	if width + 1 > limit
		let l:content = strpart(l:content, 0, limit - 1)
		let width = len(l:content)
	endif
	" prevent scrolling caused by multiple echo
	redraw 
	if a:highlight != 0
		echohl Type
		echo l:content
		echohl NONE
	else
		echo l:content
	endif
	if saveshow != 0
		set showmode
	endif
endfunc


"----------------------------------------------------------------------
" path basic
"----------------------------------------------------------------------
let s:windows = (has('win95') || has('win32') || has('win64') || has('win16'))


"----------------------------------------------------------------------
" miniwin_name
"----------------------------------------------------------------------
function! asclib#miniwin_name() abort
	if !exists('s:buffer_seqno')
		let s:buffer_seqno = 0
	endif
    if !exists('t:asclib_miniwin_buf_name')
        let s:buffer_seqno += 1
        let t:asclib_miniwin_buf_name = '__MiniWin__.' . s:buffer_seqno
    endif
    return t:asclib_miniwin_buf_name
endfunc


"----------------------------------------------------------------------
" open mini window below the tagbar
"----------------------------------------------------------------------
function! asclib#miniwin_toggle()
	let mark_win = asclib#window#search('quickfix', 'qf', 0)
	let mini_win = asclib#window#search('nofile', 'miniwin', 0)
	if mark_win == 0
		if mini_win > 0
			let uid = asclib#window#uid('%', '%')
			silent! exec ''.mini_win.'wincmd w'
			silent! close
			if exists('t:asclib_miniwin')
				unlet t:asclib_miniwin
			endif
			call asclib#window#goto_uid(uid)
		endif
	else
		let height = get(g:, 'asclib_miniwin_height', 10)
		let width = get(g:, 'asclib_miniwin_width', 80)
		let mark_uid = asclib#window#uid('%', mark_win)
		if mini_win == 0
			let uid = asclib#window#uid('%', '%')
			silent! exec ''.mark_win.'wincmd w'
			let view = winsaveview()
			exec "vs ".asclib#miniwin_name()
			"exec 'belowright '.height.'split '.asclib#miniwin_name()
			setlocal buftype=nofile 
			setlocal filetype=miniwin
			setlocal nomodifiable
			setlocal nonumber
			setlocal signcolumn=no
			setlocal statusline=[miniwin]
			setlocal wrap
			call asclib#window#goto_uid(mark_uid)
			call winrestview(view)
			call asclib#window#goto_uid(uid)
		endif
	endif
endfunc


"----------------------------------------------------------------------
" asclib#miniwin_display
"----------------------------------------------------------------------
function! asclib#miniwin_display(string)
	let wid = asclib#window#search('nofile', 'miniwin', 0)
	if wid == 0
		return
	endif
	let uid = asclib#window#uid('%', '%')
	let xid = asclib#window#uid('%', wid)
	noautocmd call asclib#window#goto_uid(xid)
	let save = @0
	setlocal modifiable
	silent exec "normal! ggVGx"
	let @" = a:string
	silent exec "normal! ggPgg"
	let @" = save
	setlocal nomodifiable
	noautocmd call asclib#window#goto_uid(uid)
endfunc


"----------------------------------------------------------------------
" toggle tagbar and miniwin together
"----------------------------------------------------------------------
function! asclib#miniwin_quickfix_toggle()
	silent call vimmake#toggle_quickfix(6)
	silent call asclib#miniwin_toggle()
endfunc


"----------------------------------------------------------------------
" lint - 
"----------------------------------------------------------------------

" python - pylint
function! asclib#lint_pylint(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path#runtime('tools/conf/pylint.conf') 
	let cmd = 'pylint --rcfile='.shellescape(rc).' --disable=W'
	let cmd = cmd .' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc

" python - flake8
function! asclib#lint_flake8(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path#runtime('tools/conf/flake8.conf') 
	let cmd = 'flake8 --config='.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc

" c/c++ - cppcheck
function! asclib#lint_cppcheck(filename)
	if !exists('g:asclib#lint_cppcheck_parameters')
		let g:asclib#lint_cppcheck_parameters = '--library=windows'
		let g:asclib#lint_cppcheck_parameters.= ' --quiet'
		let g:asclib#lint_cppcheck_parameters.= ' --enable=warning'
		let g:asclib#lint_cppcheck_parameters.= ',performance,portability'
		let g:asclib#lint_cppcheck_parameters.= ' -DWIN32 -D_WIN32'
	endif
	let filename = (a:filename == '')? expand('%') : a:filename
	let cfg = g:asclib#lint_cppcheck_parameters
	let cmd = 'cppcheck '.cfg.' '.shellescape(filename)
	call vimmake#run('', {'auto':'make'}, cmd)
endfunc

" c - splint
function! asclib#lint_splint(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path#runtime('tools/conf/splint.conf') 
	let cmd = 'splint -f '.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc


"----------------------------------------------------------------------
" open something
"----------------------------------------------------------------------
let s:config = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')

" call winhlp32.exe to open .hlp
function! asclib#open_win32_help(hlp, keyword)
	if !filereadable(a:hlp)
		call asclib#errmsg('can not open: '.a:hlp)
		return 1
	endif
	if asclib#path#which('winhlp32.exe') == ''
		call asclib#errmsg('can not find WinHlp32.exe, please install it')
		return 2
	endif
	if executable('python')
		let path = s:config
		let cmd = 'python '
		let cmd .= path . '/lib/vimhelp.py -h '.shellescape(a:hlp)
		if a:keyword != ''
			let cmd .= ' ' . shellescape(a:keyword)
		endif
		exec 'VimMake -mode=5 '.cmd
		return 0
	endif
	let cmd = 'WinHlp32.exe '
	if a:keyword != ''
		let kw = split(a:keyword, ' ')[0]
		if kw != ''
			let cmd .= '-k '.kw. ' '
		endif
	endif
	exec 'VimMake -mode=5 '.cmd. shellescape(a:hlp)
	return 0
endfunc


function! asclib#open_win32_chm(chm, keyword)
	if !filereadable(a:chm)
		call asclib#errmsg('can not open: '.a:chm)
		return 1
	endif
	if a:keyword == ''
		silent exec 'VimMake -mode=5 '.shellescape(a:chm)
		return 0
	else
		if asclib#path#which('KeyHH.exe') == ''
			call asclib#errmsg('can not find KeyHH.exe, please install it')
			return 2
		endif
	endif
	let chm = shellescape(a:chm)
	let cmd = 'KeyHH.exe -\#klink '.shellescape(a:keyword).' '.chm
	silent exec '!start /b '.cmd
endfunc


"----------------------------------------------------------------------
" smooth interface
"----------------------------------------------------------------------
function! s:smooth_scroll(dir, dist, duration, speed)
	for i in range(a:dist/a:speed)
		let start = reltime()
		if a:dir ==# 'd'
			exec 'normal! '. a:speed."\<C-e>".a:speed."j"
		else
			exec 'normal! '. a:speed."\<C-y>".a:speed."k"
		endif
		redraw
		let elapsed = s:get_ms_since(start)
		let snooze = float2nr(a:duration - elapsed)
		if snooze > 0
			exec "sleep ".snooze."m"
		endif
	endfor
endfunc

function! s:get_ms_since(time)
	let cost = split(reltimestr(reltime(a:time)), '\.')
	return str2nr(cost[0]) * 1000 + str2nr(cost[1]) / 1000.0
endfunc

function! asclib#smooth_scroll_up(dist, duration, speed)
	call s:smooth_scroll('u', a:dist, a:duration, a:speed)
endfunc

function! asclib#smooth_scroll_down(dist, duration, speed)
	call s:smooth_scroll('d', a:dist, a:duration, a:speed)
endfunc


"----------------------------------------------------------------------
" gprof
"----------------------------------------------------------------------
function! asclib#open_gprof(image, profile)
	let l:image = a:image
	let l:profile = a:profile
	if asclib#path#executable('gprof') == ''
		call s:errmsg('cannot find gprof')
		return
	endif
	if l:image == ''
		let l:image = expand("%:p:h") . '/' . expand("%:t:r") 
		let l:image.= s:windows? '.exe' : ''
		if l:profile == ''
			let l:profile = expand("%:p:h") . '/gmon.out'
		endif
	elseif l:profile == ''
		let l:profile = 'gmon.out'
	endif
	let command = 'gprof '.shellescape(l:image).' '.shellescape(l:profile)
	let text = vimmake#python_system(command)
	let text = substitute(text, '\r', '', 'g')
	vnew
	let l:save = @0
	let @0 = text
	normal! "0P
	let @0 = l:save
	setlocal buftype=nofile bufhidden=delete nobuflisted nomodifiable
	setlocal noshowcmd noswapfile nowrap nonumber signcolumn=no nospell
	setlocal fdc=0 nolist colorcolumn= nocursorline nocursorcolumn
	setlocal noswapfile norelativenumber
	setlocal filetype=gprof
endfunc


"----------------------------------------------------------------------
" execute scripts in string
"----------------------------------------------------------------------
function! asclib#eval_text(string) abort
	let partial = []
	let index = 0
	while 1
		let pos = stridx(a:string, '%{', index)
		if pos < 0
			let partial += [strpart(a:string, index)]
			break
		endif
		let head = ''
		if pos > index
			let partial += [strpart(a:string, index, pos - index)]
		endif
		let endup = stridx(a:string, '}', pos + 2)
		if endup < 0
			let partial += [strpart(a:stirng, index)]
			break
		endif
		let index = endup + 1
		if endup > pos + 2
			let script = strpart(a:string, pos + 2, endup - (pos + 2))
			let script = substitute(script, '^\s*\(.\{-}\)\s*$', '\1', '')
			let result = eval(script)
			let partial += [result]
		endif
	endwhile
	return join(partial, '')
endfunc


"----------------------------------------------------------------------
" ask text
"----------------------------------------------------------------------
function! asclib#input_text(string) abort
	let partial = []
	let index = 0
	while 1
		let pos = stridx(a:string, '%{', index)
		if pos < 0
			let partial += [strpart(a:string, index)]
			break
		endif
		let head = ''
		if pos > index
			let partial += [strpart(a:string, index, pos - index)]
		endif
		let endup = stridx(a:string, '}', pos + 2)
		if endup < 0
			let partial += [strpart(a:stirng, index)]
			break
		endif
		let index = endup + 1
		if endup > pos + 2
			let script = strpart(a:string, pos + 2, endup - (pos + 2))
			let script = substitute(script, '^\s*\(.\{-}\)\s*$', '\1', '')
			let varname = script
			let default = ""
			let pos = stridx(script, '=')
			if pos >= 0
				let varname = strpart(script, 0, pos)
				let default = strpart(script, pos + 1)
			endif
			if varname == ''
				if default != ''
					let result = eval(devault)
				endif
			else
				redraw
				let result = input('input ('.varname.'): ', default)
				redraw
				if result == ''
					return ''
				endif
			endif
			let partial += [result]
		endif
	endwhile
	return join(partial, '')
endfunc


"----------------------------------------------------------------------
" snips
"----------------------------------------------------------------------

function! asclib#snip_insert(text, mode)
	let text = asclib#input_text(a:text)
	if text == ''
		return ""
	endif
	if stridx(text, '@') < 0
		let text .= '@'
	endif
	let save = @z
	let @z = text
	silent exec 'normal! "z]p'
	let @z = save
	call search('@')
	if a:mode == 0
		call feedkeys('s', 'm')
	else
		call feedkeys("\<del>", "m")
	endif
	return ""
endfunc



"----------------------------------------------------------------------
" find and touch a file (usually a wsgi file)
"----------------------------------------------------------------------
function! asclib#touch_file(name)
	if has('win32') || has('win64') || has('win16') || has('win95')
		echo 'touching is not supported on windows'
		return
	endif
	let l:filename = findfile(a:name, '.;')
	if l:filename == ''
		echo 'not find: "'.a:name .'"'
	else
		call system('touch ' . shellescape(l:filename) . ' &')
		echo 'touch: '. l:filename
	endif
endfunc


"----------------------------------------------------------------------
" prettify html
"----------------------------------------------------------------------
function! asclib#html_prettify()
	if &ft != 'html'
		echo "not a html file"
		return
	endif
	silent! exec "s/<[^>]*>/\r&\r/g"
	silent! exec "g/^$/d"
	exec "normal ggVG="
endfunc



"----------------------------------------------------------------------
" owncloud
"----------------------------------------------------------------------
if !exists('g:asclib#owncloud')
	let g:asclib#owncloud = ['', '', '']
endif

if !exists('g:asclib#owncloudcmd')
	let g:asclib#owncloudcmd = ''
endif


function! asclib#owncloud_call(command)
	let cmd = g:asclib#owncloudcmd
	if cmd == ''
		let cmd = asclib#path#executable('owncloudcmd')
	endif
	if cmd == '' && s:windows != 0
		if filereadable('C:/Program Files (x86)/ownCloud/owncloudcmd.exe')
			let cmd = 'C:/Program Files (x86)/ownCloud/owncloudcmd.exe'
		elseif filereadable('C:/Program Files/ownCloud/owncloudcmd.exe')
			let cmd = 'C:/Program Files/ownCloud/owncloudcmd.exe'
		endif
	endif
	if cmd == ''
		call asclib#errmsg("cannot find owncloudcmd")		
		return
	endif
	call vimmake#run('', {}, shellescape(cmd) . ' ' . a:command)
endfunc


function! asclib#owncloud_sync()
	let cloud = expand('~/.vim/cloud')
	try
		silent call mkdir(cloud, "p", 0755)
	catch /^Vim\%((\a\+)\)\=:E/
	finally
	endtry
	if type(g:asclib#owncloud) != type([])
		call asclib#errmsg("bad g:asclib#owncloud config")
		return
	endif
	if len(g:asclib#owncloud) != 3
		call asclib#errmsg("bad g:asclib#owncloud config")
		return
	endif
	let url = g:asclib#owncloud[0]
	let cloud_user = g:asclib#owncloud[1]
	let cloud_pass = g:asclib#owncloud[2]
	if strpart(url, 0, 5) != 'http:' && strpart(url, 0, 6) != 'https:'
		call asclib#errmsg("bad g:asclib#owncloud[0] config")
		return
	endif
	if cloud_user == ''
		call asclib#errmsg("bad g:asclib#owncloud[1] config")
		return
	endif
	let cmd = '-u ' .shellescape(cloud_user) . ' '
	if cloud_pass
		let cmd .= '-p ' .shellescape(cloud_pass) . ' '
	endif
	let cmd .= '--trust --non-interactive '
	let cmd .= (s:windows == 0)? '--exclude /dev/null ' : ''
	let cmd .= shellescape(cloud) . ' ' . shellescape(url)
	call asclib#owncloud_call(cmd)
endfunc


function! asclib#show_rtp()
	for key in split(&rtp, ',')
		echo key
	endfor
endfunc


function! asclib#quickfix_title(title)
	if !has('nvim')
		if v:version >= 800 || has('patch-7.4.2210')
			call setqflist([], 'a', {'title': a:title})
			redrawstatus!
		else
			call setqflist([], 'a')
		endif
	else
		call setqflist([], 'a', a:title)
		redrawstatus!
	endif
endfunc


"----------------------------------------------------------------------
" bash for windows 
"----------------------------------------------------------------------
function! asclib#wsl_bash(cwd)
	let root = $SystemRoot
	let test1 = root . '/system32/bash.exe'
	let test2 = root . '/SysNative/bash.exe'
	let cd = haslocaldir()? 'lcd ' : 'cd '
	let cwd = getcwd()
	if executable(test1)
		let name = test1
	elseif executable(test2)
		let name = test2
	else
		call asclib#errmsg('can not find bash for window')
		return
	endif
	if a:cwd != ''
		if a:cwd == '%'
			exec cd . fnameescape(expand('%:p:h'))
		else
			exec cd . fnameescape(a:cwd)
		endif
	endif
	silent exec 'silent !start '. fnameescape(name)
	if a:cwd != ''
		exec cd . fnameescape(cwd)
	endif
endfunc


"----------------------------------------------------------------------
" change color
"----------------------------------------------------------------------
function! asclib#color_switch(names)
	if !exists('s:color_index')
		let s:color_index = 0
	endif
	if len(a:names) == 0
		return
	endif
	if s:color_index >= len(a:names)
		let s:color_index = 0
	endif
	let color = a:names[s:color_index]
	let s:color_index += 1
	exec 'color '.fnameescape(color)
	redraw! | echo "" | redraw!
	echo 'color '.color
endfunc


