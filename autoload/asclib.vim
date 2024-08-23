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
	redraw
	echohl ErrorMsg
	echom a:msg
	echohl NONE
endfunc


"----------------------------------------------------------------------
" path basic
"----------------------------------------------------------------------
let s:windows = (has('win95') || has('win32') || has('win64') || has('win16'))


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
	call asyncrun#run('', opt, cmd)
endfunc

" python - flake8
function! asclib#lint_flake8(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path#runtime('tools/conf/flake8.conf') 
	let cmd = 'flake8 --config='.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call asyncrun#run('', opt, cmd)
endfunc

" c/c++ - cppcheck
function! asclib#lint_cppcheck(filename)
	if !exists('g:asclib#lint_cppcheck_parameters')
		let g:asclib#lint_cppcheck_parameters = '--library=windows'
		let g:asclib#lint_cppcheck_parameters.= ' --quiet'
		let g:asclib#lint_cppcheck_parameters.= ' --enable=warning'
		let g:asclib#lint_cppcheck_parameters.= ',performance,portability'
		let g:asclib#lint_cppcheck_parameters.= ',style'
		let g:asclib#lint_cppcheck_parameters.= ' -DWIN32 -D_WIN32'
	endif
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path#runtime('tools/conf/cppcheck.conf')
	let cfg = g:asclib#lint_cppcheck_parameters
	if filereadable(rc)
		let cfg .= ' --suppressions-list=' . shellescape(rc)
	endif
	let cmd = 'cppcheck '.cfg.' '.shellescape(filename)
	call asyncrun#run('', {'auto':'make', 'raw':1}, cmd)
endfunc

" c - splint
function! asclib#lint_splint(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path#runtime('tools/conf/splint.conf') 
	let cmd = 'splint -f '.shellescape(rc).' '.shellescape(filename)
	" let cmd .= ' -showfunc -hints +quiet -parenfileformat -linelen 999 '
	let cmd .= ' -showfunc +quiet -parenfileformat -linelen 999 '
	let opt = {'auto': "make", "raw":1}
	call asyncrun#run('', opt, cmd)
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
	let text = asclib#core#system(command)
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
" nextcloud
"----------------------------------------------------------------------
if !exists('g:asclib#nextcloud')
	let g:asclib#nextcloud = ['', '', '']
endif

if !exists('g:asclib#nextcloudcmd')
	let g:asclib#nextcloudcmd = ''
endif


function! asclib#nextcloud_call(command)
	let cmd = g:asclib#nextcloudcmd
	if cmd == ''
		let cmd = asclib#path#executable('nextcloudcmd')
	endif
	if cmd == '' && s:windows != 0
		if filereadable('C:/Program Files (x86)/nextcloud/nextcloudcmd.exe')
			let cmd = 'C:/Program Files (x86)/nextcloud/nextcloudcmd.exe'
		elseif filereadable('C:/Program Files/nextcloud/nextcloudcmd.exe')
			let cmd = 'C:/Program Files/nextcloud/nextcloudcmd.exe'
		endif
	endif
	if cmd == ''
		call asclib#errmsg("cannot find nextcloudcmd")		
		return
	endif
	call vimmake#run('', {}, shellescape(cmd) . ' ' . a:command)
endfunc


function! asclib#nextcloud_sync()
	let cloud = expand('~/.vim/cloud')
	try
		silent call mkdir(cloud, "p", 0755)
	catch /^Vim\%((\a\+)\)\=:E/
	finally
	endtry
	if type(g:asclib#nextcloud) != type([])
		call asclib#errmsg("bad g:asclib#nextcloud config")
		return
	endif
	if len(g:asclib#nextcloud) != 3
		call asclib#errmsg("bad g:asclib#nextcloud config")
		return
	endif
	let url = g:asclib#nextcloud[0]
	let cloud_user = g:asclib#nextcloud[1]
	let cloud_pass = g:asclib#nextcloud[2]
	if strpart(url, 0, 5) != 'http:' && strpart(url, 0, 6) != 'https:'
		call asclib#errmsg("bad g:asclib#nextcloud[0] config")
		return
	endif
	if cloud_user == ''
		call asclib#errmsg("bad g:asclib#nextcloud[1] config")
		return
	endif
	let cmd = '-u ' .shellescape(cloud_user) . ' '
	if cloud_pass
		let cmd .= '-p ' .shellescape(cloud_pass) . ' '
	endif
	let cmd .= '--trust --non-interactive '
	let cmd .= (s:windows == 0)? '--exclude /dev/null ' : ''
	let cmd .= shellescape(cloud) . ' ' . shellescape(url)
	call asclib#nextcloud_call(cmd)
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


