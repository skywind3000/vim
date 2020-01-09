" vimmake.vim - Enhenced Customize Make system for vim
"
" Settings:
"     g:vimmake_path - change the path of tools rather than ~/.vim/
"     g:vimmake_mode - dictionary of invoke mode of each tool
"     g:vimmake_open - open quickfix window at given height
"
" Setup mode for command: ~/.vim/vimmake.{name}
"     let g:vimmake_mode["name"] = "{mode}"
"     {mode} can be:
"		"normal"	- launch the tool and return to vim after exit (default)
"		"quickfix"	- launch and redirect output to quickfix
"		"bg"		- launch background and discard any output
"		"async"		- run in async mode and redirect output to quickfix
"
"	  note: "g:vimmake_mode" must be initialized to "{}" at first
"
" Emake can be installed to /usr/local/bin to build C/C++ by:
"     $ wget https://skywind3000.github.io/emake/emake.py
"     $ sudo python emake.py -i
"
"

" vim: set et fenc=utf-8 ff=unix sts=8 sw=4 ts=4 :


"----------------------------------------------------------------------
"- Global Variables
"----------------------------------------------------------------------

" default tool location is ~/.vim which could be changed by g:vimmake_path
if !exists("g:vimmake_path")
	let g:vimmake_path = "~/.vim"
endif

" default cc executable
if !exists("g:vimmake_cc")
	let g:vimmake_cc = "gcc"
endif

" default gcc cflags
if !exists("g:vimmake_cflags")
	let g:vimmake_cflags = []
endif

" default VimMake mode
if !exists("g:vimmake_default")
	let g:vimmake_default = 0
endif

" tool modes
if !exists("g:vimmake_mode")
	let g:vimmake_mode = {}
endif

" save file
if !exists("g:vimmake_save")
	let g:vimmake_save = 0
endif

" build info
if !exists('g:vimmake_text')
	let g:vimmake_text = ''
endif

" whether to change directory
if !exists('g:vimmake_cwd')
	let g:vimmake_cwd = 0
endif

" main run
if !exists('g:vimmake_run_guess')
	let g:vimmake_run_guess = []
endif

" filetype -> command
if !exists('g:vimmake_ftrun')
	let g:vimmake_ftrun = {}
endif

" filetype -> VimMake sub command
if !exists('g:vimmake_ftmake')
	let g:vimmake_ftmake = {}
endif


"----------------------------------------------------------------------
" Internal Definition
"----------------------------------------------------------------------

" path where vimmake.vim locates
let s:vimmake_home = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let g:vimmake_home = s:vimmake_home
let s:vimmake_advance = 0	" internal usage, won't be modified by user
let g:vimmake_advance = 0	" external reference, may be modified by user
let s:vimmake_windows = 0	" internal usage, won't be modified by user
let g:vimmake_windows = 0	" external reference, may be modified by user

" check has advanced mode
if v:version >= 800 || has('patch-7.4.1829') || has('nvim')
	if has('job') && has('channel') && has('timers')
		let s:vimmake_advance = 1
		let g:vimmake_advance = 1
	elseif has('nvim')
		let s:vimmake_advance = 1
		let g:vimmake_advance = 1
	endif
endif

" check running in windows
if has('win32') || has('win64') || has('win95') || has('win16')
	let s:vimmake_windows = 1
	let g:vimmake_windows = 1
endif

" join two path
function! s:PathJoin(home, name)
    let l:size = strlen(a:home)
    if l:size == 0 | return a:name | endif
    let l:last = strpart(a:home, l:size - 1, 1)
    if has("win32") || has("win64") || has("win16") || has('win95')
		let l:first = strpart(a:name, 0, 1)
		if l:first == "/" || l:first == "\\"
			let head = strpart(a:home, 1, 2)
			if index([":\\", ":/"], head) >= 0
				return strpart(a:home, 0, 2) . a:name
			endif
			return a:name
		elseif index([":\\", ":/"], strpart(a:name, 1, 2)) >= 0
			return a:name
		endif
        if l:last == "/" || l:last == "\\"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    else
		if strpart(a:name, 0, 1) == "/"
			return a:name
		endif
        if l:last == "/"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    endif
endfunc

" error message
function! s:ErrorMsg(msg)
	echohl ErrorMsg
	echom 'ERROR: '. a:msg
	echohl NONE
endfunc

" show not support message
function! s:NotSupport()
	let msg = "required: +timers +channel +job and vim >= 7.4.1829"
	call s:ErrorMsg(msg)
endfunc

" run autocmd
function! s:AutoCmd(name)
	if has('autocmd') && ((g:vimmake_build_skip / 2) % 2) == 0
		exec 'silent doautocmd User AsyncRun'.a:name
	endif
endfunc

" change directory with right command
function! s:chdir(path)
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	silent execute cmd . ' '. fnameescape(a:path)
endfunc



"----------------------------------------------------------------------
"- Execute ~/.vim/vimmake.{command}
"----------------------------------------------------------------------
function! s:Cmd_VimTool(bang, ...)
	if a:0 == 0
		echohl ErrorMsg
		echom "E471: Argument required"
		echohl NONE
		return
	endif
	let l:command = a:1
	let l:target = ''
	if a:0 >= 2
		let l:target = a:2
	endif
	let l:home = expand(g:vimmake_path)
	let l:fullname = "vimmake." . l:command
	let l:fullname = s:PathJoin(l:home, l:fullname)
	let l:value = get(g:vimmake_mode, l:command, '')
	if a:bang != '!'
		try | silent wall | catch | endtry
	endif
	if type(l:value) == 0
		let l:mode = string(l:value)
	else
		let l:mode = l:value
	endif
	let l:pos = stridx(l:mode, '/')
	let l:auto = ''
	if l:pos >= 0
		let l:size = len(l:mode)
		let l:auto = strpart(l:mode, l:pos + 1)
		let l:mode = strpart(l:mode, 0, l:pos)
		if len(l:auto) > 0
			let l:auto = '-auto='.escape(matchstr(l:auto, '\w*'), ' ')
		endif
	endif
	let $VIM_TARGET = l:target
	let $VIM_SCRIPT = g:vimmake_path
	let l:fullname = shellescape(l:fullname)
	if index(['', '0', 'normal', 'default'], l:mode) >= 0
		exec 'AsyncRun -mode=4 '.l:auto.' @ '. l:fullname
	elseif index(['1', 'quickfix', 'make', 'makeprg'], l:mode) >= 0
		exec 'AsyncRun -mode=1 '.l:auto.' @ '. l:fullname
	elseif index(['2', 'system', 'silent'], l:mode) >= 0
		exec 'AsyncRun -mode=3 '.l:auto.' @ '. l:fullname
	elseif index(['3', 'background', 'bg'], l:mode) >= 0
		exec 'AsyncRun -mode=5 '.l:auto.' @ '. l:fullname
	elseif index(['6', 'async', 'job', 'channel'], l:mode) >= 0
		exec 'AsyncRun -mode=0 '.l:auto.' @ '. l:fullname
	else
		call s:ErrorMsg("invalid mode: ".l:mode)
	endif
	return l:fullname
endfunc


" command definition
command! -bang -nargs=+ VimTool call s:Cmd_VimTool('<bang>', <f-args>)


"----------------------------------------------------------------------
"- Execute Files
"----------------------------------------------------------------------
function! s:ExecuteMe(mode)
	if a:mode == 0		" Execute current filename
		let l:fname = shellescape(expand("%:p"))
		if (has('gui_running') || has('nvim')) && (s:vimmake_windows != 0)
			if !has('nvim')
				silent exec '!start cmd /C '. l:fname .' & pause'
			else
				call asyncrun#run('', {'mode':4}, l:fname)
			endif
		else
			exec '!' . l:fname
		endif
	elseif a:mode == 1	" Execute current filename without extname
		let l:fname = shellescape(expand("%:p:r"))
		if (has('gui_running') || has('nvim')) && (s:vimmake_windows != 0)
			if !has('nvim')
				silent exec '!start cmd /C '. l:fname .' & pause'
			else
				call asyncrun#run('', {'mode':4}, l:fname)
			endif
		else
			exec '!' . l:fname
		endif
	elseif a:mode == 2
		let l:fname = shellescape(expand("%"))
		if (has('gui_running') || has('nvim')) && (s:vimmake_windows != 0)
			if !has('nvim')
				silent exec '!start cmd /C emake -e '. l:fname .' & pause'
			else
				call asyncrun#run('', {'mode':4}, "emake -e ". l:fname)
			endif
		else
			exec '!emake -e ' . l:fname
		endif
	elseif a:mode == 3			" execute makefile
		let l:makeprg = get(g:, 'vimmake_mp_run', '')
		let l:fname = shellescape(expand("%"))
		if l:makeprg == ''
			if executable('make')
				let l:makeprg = 'make run -f'
			elseif executable('mingw32-make')
				let l:makeprg = 'mingw32-make run -f'
			elseif executable('mingw64-make')
				let l:makeprg = 'mingw64-make run -f'
			else
				redraw
				call s:ErrorMsg('cannot find make/mingw32-make')
				return
			endif
		endif
		if (has('gui_running') || has('nvim')) && (s:vimmake_windows != 0)
			let l:cmdline = l:makeprg. ' '.l:fname
			if !has('nvim')
				silent exec '!start cmd /C '.l:cmdline . ' & pause'
			else
				call asyncrun#run('', {'mode':4}, l:cmdline)
			endif
		else
			exec '!'.l:makeprg.' '.l:fname
		endif
	elseif a:mode == 4
		let ext = tolower(expand("%:e"))
		if index(['c', 'cc', 'cpp', 'h', 'mak', 'em', 'emk', 'm'], ext) >= 0
			call s:ExecuteMe(2)
		elseif index(['mm', 'py', 'pyw', 'cxx', 'java', 'pyx'], ext) >= 0
			call s:ExecuteMe(2)
		elseif index(['c', 'cpp', 'python', 'java', 'go'], &ft) >= 0
			call s:ExecuteMe(2)
		elseif index(['javascript'], &ft) >= 0
			call s:ExecuteMe(2)
		else
			call s:ExecuteMe(3)
		endif
	endif
endfunc


"----------------------------------------------------------------------
"- Execute current file by mode or filetype
"----------------------------------------------------------------------
function! s:Cmd_VimExecute(bang, ...)
	let l:mode = (a:0 < 1)? '' : a:1
	let l:cwd = g:vimmake_cwd
	if a:0 >= 2
		let l:cwd = a:2
	endif
	if a:bang != '!' | silent! wall | endif
	if bufname('%') == '' | return | endif
	let l:ext = tolower(expand("%:e"))
	let l:savecwd = getcwd()
	if l:cwd
		if l:cwd == 1
			let l:dest = expand('%:p:h')
		elseif l:cwd == 2
			let l:dest = asyncrun#get_root('%')
		else
			let l:dest = asyncrun#get_root('%')
		endif
		silent! call s:chdir(l:dest)
	endif
	if index(['', '0', 'file', 'filename'], l:mode) >= 0
		call s:ExecuteMe(0)
	elseif index(['1', 'main', 'mainname', 'noext', 'exe'], l:mode) >= 0
		call s:ExecuteMe(1)
	elseif index(['2', 'emake'], l:mode) >= 0
		call s:ExecuteMe(2)
	elseif index(['3', 'make'], l:mode) >= 0
		call s:ExecuteMe(3)
	elseif index(['4', 'automake', 'auto'], l:mode) >= 0
		call s:ExecuteMe(4)
	elseif index(['c', 'cpp', 'cc', 'm', 'mm', 'cxx'], l:ext) >= 0
		call s:ExecuteMe(1)
	elseif index(['h', 'hh', 'hpp'], l:ext) >= 0
		call s:ExecuteMe(1)
	elseif index(g:vimmake_run_guess, l:ext) >= 0
		call s:ExecuteMe(1)
	elseif index(['mak', 'emake', 'em', 'emk'], l:ext) >= 0
		call s:ExecuteMe(2)
	elseif l:ext == 'mk'
		call s:ExecuteMe(3)
	elseif &filetype == "vim"
		exec 'source ' . fnameescape(expand("%"))
	elseif (has('gui_running') || has('nvim')) && (s:vimmake_windows != 0)
		let l:cmd = get(g:vimmake_ftrun, &ft, '')
		let l:fname = shellescape(expand("%"))
		if l:cmd == ''
			if &ft == 'python'
				let l:cmd = 'python'
			elseif &ft == 'javascript'
				let l:cmd = 'node'
			elseif &ft == 'sh'
				let l:cmd = 'sh'
			elseif &ft == 'lua'
				let l:cmd = 'lua'
			elseif &ft == 'perl'
				let l:cmd = 'perl'
			elseif &ft == 'ruby'
				let l:cmd = 'ruby'
			elseif &ft == 'php'
				let l:cmd = 'php'
			elseif l:ext == 'vbs'
				let l:cmd = 'cscript -nologo'
			elseif l:ext == 'ps1'
				let l:cmd = 'powershell -file'
			elseif l:ext == 'zsh'
				let l:cmd = 'zsh'
			elseif index(['osa', 'scpt', 'applescript'], l:ext) >= 0
				let l:cmd = 'osascript'
			endif
		endif
		if l:cmd == ''
			call s:ExecuteMe(0)
		elseif !has('nvim')
			silent exec '!start cmd /C '. l:cmd . ' ' . l:fname . ' & pause'
		else
			call asyncrun#run('', {'mode':4}, l:cmd . ' ' . l:fname)
		endif
	else
		let l:cmd = get(g:vimmake_ftrun, &ft, '')
		if l:cmd != ''
			exec '!'. l:cmd . ' ' . shellescape(expand("%"))
		elseif &ft == 'python'
			exec '!python ' . shellescape(expand("%"))
		elseif &ft == 'javascript'
			exec '!node ' . shellescape(expand("%"))
		elseif &ft == 'sh'
			exec '!sh ' . shellescape(expand("%"))
		elseif &ft == 'lua'
			exec '!lua ' . shellescape(expand("%"))
		elseif &ft == 'perl'
			exec '!perl ' . shellescape(expand("%"))
		elseif &ft == 'ruby'
			exec '!ruby ' . shellescape(expand("%"))
		elseif &ft == 'php'
			exec '!php ' . shellescape(expand("%"))
		elseif &ft == 'zsh'
			exec '!zsh '. shellescape(expand("%"))
		elseif index(['osa', 'scpt', 'applescript'], l:ext) >= 0
			exec '!osascript '. shellescape(expand('%'))
		else
			call s:ExecuteMe(0)
		endif
	endif
	if l:cwd > 0
		call s:chdir(l:savecwd)
	endif
endfunc


" command definition
command! -bang -nargs=* VimExecute call s:Cmd_VimExecute('<bang>', <f-args>)
command! -bang -nargs=? VimRun call s:Cmd_VimExecute('<bang>', '?', <f-args>)



"----------------------------------------------------------------------
"- build via gcc/make/emake
"----------------------------------------------------------------------
function! s:Cmd_VimBuild(bang, ...)
	if bufname('%') == '' | return | endif
	if a:0 == 0
		echohl ErrorMsg
		echom "E471: Argument required"
		echohl NONE
		return
	endif
	if a:bang != '!'
		silent! update
	endif
	let l:what = a:1
	let l:conf = ""
	if a:0 >= 2
		let l:conf = a:2
	endif
	let vimmake = 'AsyncRun '
	if g:vimmake_build_name != ''
		let vimmake .= '-auto='.fnameescape(g:vimmake_build_name).' '
	endif
	if index(['0', 'gcc', 'cc'], l:what) >= 0
		if has_key(g:vimmake_ftmake, &ft)
			let command = g:vimmake_ftmake[&ft]
			exec vimmake .command
		else
			let l:filename = expand("%")
			let l:source = shellescape(l:filename)
			let l:output = shellescape(fnamemodify(l:filename, ':r'))
			let l:cc = (g:vimmake_cc == '')? 'gcc' : g:vimmake_cc
			let l:flags = join(g:vimmake_cflags, ' ')
			let l:extname = expand("%:e")
			if index(['cpp', 'cc', 'cxx', 'mm'], l:extname) >= 0
				let l:flags .= ' -lstdc++'
			endif
			let l:cmd = l:cc . ' -Wall '. l:source . ' -o ' . l:output
			let l:cmd .= (l:conf == '')? '' : (' '. l:conf)
			exec vimmake .l:cmd . ' ' . l:flags
		endif
	elseif index(['1', 'make'], l:what) >= 0
		if l:conf == ''
			exec vimmake .'@ make'
		else
			exec vimmake .'@ make '.shellescape(l:conf)
		endif
	elseif index(['2', 'emake'], l:what) >= 0
		let l:source = shellescape(expand("%"))
		if l:conf == ''
			exec vimmake .'@ emake "$(VIM_FILEPATH)"'
		else
			exec vimmake .'@ emake --ini='.shellescape(l:conf).' '.l:source
		endif
	elseif index(['3', 'gnumake'], l:what) >= 0
		let l:makeprg = get(g:, 'vimmake_mp_make', '')
		let l:fname = shellescape(expand("%:t"))
		if l:makeprg == ''
			if executable('make')
				let l:makeprg = 'make -f'
			elseif executable('mingw32-make')
				let l:makeprg = 'mingw32-make -f'
			elseif executable('mingw64-make')
				let l:makeprg = 'mingw64-make -f'
			else
				redraw
				call s:ErrorMsg('cannot find make/mingw32-make')
				return
			endif
		endif
		let vimmake = vimmake . '-cwd=$(VIM_FILEDIR) @ '
		if l:conf == ''
			exec vimmake . l:makeprg. ' '.l:fname
		else
			exec vimmake . l:makeprg. ' '.l:fname . ' '.l:conf
		endif
	elseif index(['4', 'automake', 'auto'], l:what) >= 0
		let ext = tolower(expand('%:e'))
		let mode = 0
		if index(['c', 'cc', 'cpp', 'h', 'mak', 'em', 'emk', 'm'], ext) >= 0
			let mode = 0
		elseif index(['mm', 'py', 'pyw', 'cxx', 'java', 'pyx'], ext) >= 0
			let mode = 0
		elseif index(['c', 'cpp', 'python', 'java', 'go'], &ft) >= 0
			let mode = 0
		elseif index(['javascript'], &ft) >= 0
			let mode = 0
		else
			let mode = 1
		endif
		if mode == 0
			if l:conf == ''
				call s:Cmd_VimBuild(a:bang, '2')
			else
				call s:Cmd_VimBuild(a:bang, '2', l:conf)
			endif
		else
			if l:conf == ''
				call s:Cmd_VimBuild(a:bang, '3')
			else
				call s:Cmd_VimBuild(a:bang, '3', l:conf)
			endif
		endif
	endif
endfunc


command! -bang -nargs=* VimBuild call s:Cmd_VimBuild('<bang>', <f-args>)



"----------------------------------------------------------------------
" get full filename, '' as current cwd, '%' as current buffer
"----------------------------------------------------------------------


"----------------------------------------------------------------------
" grep code
"----------------------------------------------------------------------
if !exists('g:vimmake_grep_exts')
	let g:vimmake_grep_exts = ['c', 'cpp', 'cc', 'h', 'hpp', 'hh', 'as']
	let g:vimmake_grep_exts += ['m', 'mm', 'py', 'js', 'php', 'java', 'vim']
	let g:vimmake_grep_exts += ['asm', 's', 'pyw', 'lua', 'go', 'rs']
endif

function! vimmake#grep(text, cwd)
	let mode = get(g:, 'vimmake_grep_mode', '')
	let fixed = get(g:, 'vimmake_grep_fixed', 0)
	if mode == ''
		let mode = (s:vimmake_windows == 0)? 'grep' : 'findstr'
	endif
	if mode == 'grep'
		let l:inc = ''
		for l:item in g:vimmake_grep_exts
			if s:vimmake_windows == 0
				let l:inc .= " --include='*." . l:item . "'"
			else
				let l:inc .= " --include=*." . l:item
			endif
		endfor
		if a:cwd == '.' || a:cwd == ''
			let l:inc .= ' *'
		else
			let l:full = asyncrun#fullname(a:cwd)
			let l:inc .= ' '.shellescape(l:full)
		endif
		let cmd = 'grep -n -s -R ' . (fixed? '-F ' : '')
		let cmd .= shellescape(a:text). l:inc .' /dev/null'
		call asyncrun#run('', {}, cmd)
	elseif mode == 'findstr'
		let l:inc = ''
		for l:item in g:vimmake_grep_exts
            if a:cwd == '.' || a:cwd == ''
                let l:inc .= '*.'.l:item.' '
            else
                let l:full = asyncrun#fullname(a:cwd)
				let l:inc .= '"%CD%/*.'.l:item.'" '
            endif
		endfor
		let options = { 'cwd':a:cwd }
		call asyncrun#run('', options, 'findstr /n /s /C:"'.a:text.'" '.l:inc)
	elseif mode == 'ag'
		let inc = []
		for item in g:vimmake_grep_exts
			let inc += ['\.'.item]
		endfor
		let cmd = 'ag ' . (fixed? '-F ' : '')
		if len(inc) > 0
			let cmd .= '-G '.shellescape('('.join(inc, '|').')$'). ' '
		endif
		let cmd .= '--nogroup --nocolor '.shellescape(a:text)
        if a:cwd != '.' && a:cwd != ''
			let cmd .= ' '. shellescape(asyncrun#fullname(a:cwd))
        endif
		call asyncrun#run('', {'mode':0}, cmd)
	elseif mode == 'rg'
		let cmd = 'rg -n --no-heading --color never '. (fixed? '-F ' : '')
		for item in g:vimmake_grep_exts
			let cmd .= ' -g *.'. item
		endfor
		let cmd .= ' '. shellescape(a:text)
		if a:cwd != '.' && a:cwd != ''
			let cmd .= ' '. shellescape(asyncrun#fullname(a:cwd))
		endif
		call asyncrun#run('', {'mode':0}, cmd)
	endif
endfunc

function! s:Cmd_GrepCode(bang, what, ...)
    let l:cwd = (a:0 == 0)? fnamemodify(expand('%'), ':h') : a:1
    if a:bang != ''
        let l:cwd = asyncrun#get_root(l:cwd)
    endif
    if l:cwd != ''
        let l:cwd = asyncrun#fullname(l:cwd)
    endif
    call vimmake#grep(a:what, l:cwd)
	let title = 'GrepCode' . a:bang . ' '. a:what
	if has('nvim') == 0 && (v:version >= 800 || has('patch-7.4.2210'))
		call setqflist([], 'a', {'title':title})
	elseif has('nvim') && has('nvim-0.2.2')
		call setqflist([], 'a', {'title':title})
	elseif has('nvim')
		call setqflist([], 'a', title)
	endif
endfunc

command! -bang -nargs=+ GrepCode call s:Cmd_GrepCode('<bang>', <f-args>)



"----------------------------------------------------------------------
" cscope easy
"----------------------------------------------------------------------
function! s:Cmd_VimScope(bang, what, name)
	let l:text = ''
	if a:what == '0' || a:what == 's'
		let l:text = 'symbol "'.a:name.'"'
	elseif a:what == '1' || a:what == 'g'
		let l:text = 'definition of "'.a:name.'"'
	elseif a:what == '2' || a:what == 'd'
		let l:text = 'functions called by "'.a:name.'"'
	elseif a:what == '3' || a:what == 'c'
		let l:text = 'functions calling "'.a:name.'"'
	elseif a:what == '4' || a:what == 't'
		let l:text = 'string "'.a:name.'"'
	elseif a:what == '6' || a:what == 'e'
		let l:text = 'egrep "'.a:name.'"'
	elseif a:what == '7' || a:what == 'f'
		let l:text = 'file "'.a:name.'"'
	elseif a:what == '8' || a:what == 'i'
		let l:text = 'files including "'.a:name.'"'
	elseif a:what == '9' || a:what == 'a'
		let l:text = 'assigned "'.a:name.'"'
	endif
	let ncol = col('.')
	let nrow = line('.')
	let nbuf = winbufnr('%')
	silent cexpr "[cscope ".a:what.": ".l:text."]"
	let success = 1
	try
		exec 'cs find '.a:what.' '.fnameescape(a:name)
	catch /^Vim\%((\a\+)\)\=:E259/
		echohl ErrorMsg
		echo "E259: not find '".a:name."'"
		echohl NONE
		let success = 0
	catch /^Vim\%((\a\+)\)\=:E567/
		echohl ErrorMsg
		echo "E567: no cscope connections"
		echohl NONE
		let success = 0
	catch /^Vim\%((\a\+)\)\=:E/
		echohl ErrorMsg
		echo "ERROR: cscope error"
		echohl NONE
		let success = 0
	endtry
	if winbufnr('%') == nbuf
		call cursor(nrow, ncol)
	endif
	if success != 0 && a:bang != '!'
		if has('autocmd')
			doautocmd User VimScope
		endif
	endif
	redrawstatus!
	redraw!
endfunc

command! -nargs=* -bang VimScope call s:Cmd_VimScope("<bang>", <f-args>)


"----------------------------------------------------------------------
" Keymap Setup
"----------------------------------------------------------------------
function! vimmake#keymap()
	noremap <silent><F5> :VimExecute run<cr>
	noremap <silent><F6> :VimExecute filename<cr>
	noremap <silent><F7> :VimBuild auto<cr>
	noremap <silent><F8> :VimExecute auto<cr>
	noremap <silent><F9> :VimBuild gcc<cr>
	noremap <silent><F10> :call asyncrun#quickfix_toggle(6)<cr>
	inoremap <silent><F5> <ESC>:VimExecute run<cr>
	inoremap <silent><F6> <ESC>:VimExecute filename<cr>
	inoremap <silent><F7> <ESC>:VimBuild auto<cr>
	inoremap <silent><F8> <ESC>:VimExecute auto<cr>
	inoremap <silent><F9> <ESC>:VimBuild gcc<cr>
	inoremap <silent><F10> <ESC>:call asyncrun#quickfix_toggle(6)<cr>

	" VimTool startup
	for l:index in range(10)
		exec 'noremap <leader>c'.l:index.' :VimTool ' . l:index . '<cr>'
		if has('gui_running')
			let l:button = 'F'.l:index
			if l:index == 0 | let l:button = 'F10' | endif
			exec 'noremap <S-'.l:button.'> :VimTool '. l:index .'<cr>'
			exec 'inoremap <S-'.l:button.'> <ESC>:VimTool '. l:index .'<cr>'
		endif
	endfor

	" set keymap to GrepCode
	noremap <silent><leader>cq :VimStop<cr>
	noremap <silent><leader>cQ :VimStop!<cr>
	noremap <silent><leader>cv :GrepCode <C-R>=expand("<cword>")<cr><cr>
	noremap <silent><leader>cx :GrepCode! <C-R>=expand("<cword>")<cr><cr>

	" set keymap to cscope
	if has("cscope")
		noremap <silent> <leader>cs :VimScope s <C-R><C-W><CR>
		noremap <silent> <leader>cg :VimScope g <C-R><C-W><CR>
		noremap <silent> <leader>cc :VimScope c <C-R><C-W><CR>
		noremap <silent> <leader>ct :VimScope t <C-R><C-W><CR>
		noremap <silent> <leader>ce :VimScope e <C-R><C-W><CR>
		noremap <silent> <leader>cd :VimScope d <C-R><C-W><CR>
		noremap <silent> <leader>ca :VimScope a <C-R><C-W><CR>
		noremap <silent> <leader>cf :VimScope f <C-R><C-W><CR>
		noremap <silent> <leader>ci :VimScope i <C-R><C-W><CR>
		if v:version >= 800 || has('patch-7.4.2038')
			set cscopequickfix=s+,c+,d+,i+,t+,e+,g+,f+,a+
		else
			set cscopequickfix=s+,c+,d+,i+,t+,e+,g+,f+
		endif
	endif

	" cscope update
	noremap <leader>cz1 :call vimmake#update_tags('', 'ctags', '.tags')<cr>
	noremap <leader>cz2 :call vimmake#update_tags('', 'cs', '.cscope')<cr>
	noremap <leader>cz3 :call vimmake#update_tags('!', 'ctags', '.tags')<cr>
	noremap <leader>cz4 :call vimmake#update_tags('!', 'cs', '.cscope')<cr>
	noremap <leader>cz5 :call vimmake#update_tags('', 'py', '.cscopy')<cr>
	noremap <leader>cz6 :call vimmake#update_tags('!', 'py', '.cscopy')<cr>
endfunc

command! -nargs=0 VimmakeKeymap call vimmake#keymap()

function! vimmake#load()
endfunc

" toggle quickfix window
function! vimmake#toggle_quickfix(size, ...)
	let l:mode = (a:0 == 0)? 2 : (a:1)
	function! s:WindowCheck(mode)
		if &buftype == 'quickfix'
			let s:quickfix_open = 1
			return
		endif
		if a:mode == 0
			let w:quickfix_save = winsaveview()
		else
			if exists('w:quickfix_save')
				call winrestview(w:quickfix_save)
				unlet w:quickfix_save
			endif
		endif
	endfunc
	let s:quickfix_open = 0
	let l:winnr = winnr()
	noautocmd windo call s:WindowCheck(0)
	noautocmd silent! exec ''.l:winnr.'wincmd w'
	if l:mode == 0
		if s:quickfix_open != 0
			silent! cclose
		endif
	elseif l:mode == 1
		if s:quickfix_open == 0
			exec 'botright copen '. ((a:size > 0)? a:size : ' ')
			wincmd k
		endif
	elseif l:mode == 2
		if s:quickfix_open == 0
			exec 'botright copen '. ((a:size > 0)? a:size : ' ')
			wincmd k
		else
			silent! cclose
		endif
	endif
	noautocmd windo call s:WindowCheck(1)
	noautocmd silent! exec ''.l:winnr.'wincmd w'
endfunc


" update filelist
function! vimmake#update_filelist(outname)
	let l:names = ['*.c', '*.cpp', '*.cc', '*.cxx']
	let l:names += ['*.h', '*.hpp', '*.hh', '*.py', '*.pyw', '*.java', '*.js']
	if has('win32') || has("win64") || has("win16")
		silent! exec '!dir /b ' . join(l:names, ',') . ' > '.a:outname
	else
		let l:cmd = ''
		let l:ccc = 1
		for l:name in l:names
			if l:ccc == 1
				let l:cmd .= ' -name "'.l:name . '"'
				let l:ccc = 0
			else
				let l:cmd .= ' -o -name "'.l:name. '"'
			endif
		endfor
		silent! exec '!find . ' . l:cmd . ' > '.a:outname
	endif
	redraw!
endfunc

if !exists('g:vimmake_ctags_flags')
	let g:vimmake_ctags_flags = '--fields=+niazS --extra=+q --c++-kinds=+px'
	let g:vimmake_ctags_flags.= ' --c-kinds=+p -n'
endif

function! vimmake#update_tags(cwd, mode, outname)
    if a:cwd == '!'
        let l:cwd = asyncrun#get_root('%')
    else
        let l:cwd = asyncrun#fullname(a:cwd)
        let l:cwd = fnamemodify(l:cwd, ':p:h')
    endif
    let l:cwd = substitute(l:cwd, '\\', '/', 'g')
	if a:mode == 'ctags' || a:mode == 'ct'
        let l:ctags = s:PathJoin(l:cwd, a:outname)
		if filereadable(l:ctags)
			try | call delete(l:ctags) | catch | endtry
		endif
        let l:options = {}
        let l:options['cwd'] = l:cwd
        let l:command = 'ctags -R -f '. shellescape(l:ctags)
		let l:parameters = ' '. g:vimmake_ctags_flags. ' '
		let l:parameters .= '--sort=yes '
        call asyncrun#run('', l:options, l:command . l:parameters . ' .')
	endif
	if index(['cscope', 'cs', 'pycscope', 'py'], a:mode) >= 0
		let l:fullname = s:PathJoin(l:cwd, a:outname)
		let l:fullname = asyncrun#fullname(l:fullname)
		let l:fullname = substitute(l:fullname, '\\', '/', 'g')
		let l:cscope = fnameescape(l:fullname)
		silent! exec "cs kill ".l:cscope
		let l:command = "silent! cs add ".l:cscope.' '.fnameescape(l:cwd)." "
		let l:options = {}
		let l:options['post'] = l:command
		let l:options['cwd'] = l:cwd
		if filereadable(l:fullname)
			try | call delete(l:fullname) | catch | endtry
		endif
		if a:mode == 'cscope' || a:mode == 'cs'
			let l:fullname = shellescape(l:fullname)
			call asyncrun#run('', l:options, 'cscope -b -R -f '.l:fullname)
		elseif a:mode == 'pycscope' || a:mode == 'py'
			let l:fullname = shellescape(l:fullname)
			call asyncrun#run('', l:options, 'pycscope -R -f '.l:fullname)
		endif
	endif
endfunc


" call python system to avoid window flicker on windows
function! vimmake#python_system(command)
	let text = g:vimmake_text
	let content = asyncrun#run('', {'mode': 3}, '@ ' . a:command)
	let g:vimmake_text = text
	return content
endfunc



