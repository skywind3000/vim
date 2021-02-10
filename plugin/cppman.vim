"======================================================================
"
" cppman.vim - Cppman/man intergration
"
" Maintainer: skywind3000 (at) gmail.com, 2020
"
" Last Modified: 2020/02/06 15:23
" Verision: 14
"
" Display cppman/man pages:
"     :Cppman[!] [section] keyword
"
"     When "!" is included, load pages from "man" command, otherwise
"     use "cppman" instead. For performance, run "cppman -c" to cache
"     all pages before this.
"
"     The "[section]" is only available for "man":
"         :Cppman! printf
"         :Cppman! 3 printf
"
"     Use "-k" to search sections:
"         :Cppman! -k printf
"
" Window position:
"     Option "g:cppman_open_mode" can allow you specify how to open:
"         :let g:cppman_open_mode = "vertical"
"         :let g:cppman_open_mode = "tab"
"         :let g:cppman_open_mode = "vert botright"
"         :let g:cppman_open_mode = "<auto>"
"
" Position modifiers:
"     Another way to indicate window position is using modifiers:
"         :vertical Cppman keyword
"         :tab Cppman keyword
"         :vert botright Cppman keyword
"
" Keymaps:
"     "K"       - jump to keyword under cursor
"     "CTRL+]"  - same as "K"
"
" Running on Windows:
"     It can use WSL to run cppman/man. If WSL is not available,
"     you can setup g:cppman_msys_home to use msys alternatively.
"
" C/C++ keywords help:
"     You can setup your "keywordprg" for c/cpp in your vimrc:
"         autocmd FileType c,cpp setlocal keywordprg=:Cppman
"
"     Than, you can use "K" in to lookup keywords in c/cpp files.
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :

"----------------------------------------------------------------------
" configuration
"----------------------------------------------------------------------

" for windows only, if set, use msys instead of wsl
if !exists('g:cppman_msys_home')
	let g:cppman_msys_home = ''
endif

" for windows only, WSL distribution name, when g:cppman_msys_home is unset
if !exists('g:cppman_wsl_dist')
	let g:cppman_wsl_dist = ''
endif

" open mode: tab/vert/botright vert/topleft/...
if !exists('g:cppman_open_mode')
	let g:cppman_open_mode = ''
endif

" disable keymaps ??
if !exists('g:cppman_no_keymaps')
	let g:cppman_no_keymaps = 0
endif

" max width
if !exists('g:cppman_max_width')
	let g:cppman_max_width = 200
endif


"----------------------------------------------------------------------
" internal states
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')


"----------------------------------------------------------------------
" python simulate system() on window to prevent temporary window
"----------------------------------------------------------------------
function! s:python_system(cmd, version)
	if has('nvim')
		let hr = system(a:cmd)
	elseif has('win32') || has('win64') || has('win95') || has('win16')
		if a:version < 0 || (has('python3') == 0 && has('python2') == 0)
			let hr = system(a:cmd)
			let s:shell_error = v:shell_error
			return hr
		elseif a:version == 3
			let pyx = 'py3 '
			let python_eval = 'py3eval'
		elseif a:version == 2
			let pyx = 'py2 '
			let python_eval = 'pyeval'
		else
			let pyx = 'pyx '
			let python_eval = 'pyxeval'
		endif
		exec pyx . 'import subprocess, vim'
		exec pyx . '__argv = {"args":vim.eval("a:cmd"), "shell":True}'
		exec pyx . '__argv["stdout"] = subprocess.PIPE'
		exec pyx . '__argv["stderr"] = subprocess.STDOUT'
		exec pyx . '__pp = subprocess.Popen(**__argv)'
		exec pyx . '__return_text = __pp.stdout.read()'
		exec pyx . '__pp.stdout.close()'
		exec pyx . '__return_code = __pp.wait()'
		exec 'let l:hr = '. python_eval .'("__return_text")'
		exec 'let l:pc = '. python_eval .'("__return_code")'
		let s:shell_error = l:pc
		return l:hr
	else
		let hr = system(a:cmd)
	endif
	let s:shell_error = v:shell_error
	return hr
endfunc


"----------------------------------------------------------------------
" call python system 
"----------------------------------------------------------------------
function! s:system(cmd)
	return s:python_system(a:cmd, get(g:, 'cppman_python_system', 0))
endfunc


"----------------------------------------------------------------------
" error message
"----------------------------------------------------------------------
function! s:errmsg(msg)
	echohl ErrorMsg
	echom 'ERROR: '. a:msg
	echohl NONE
endfunc


"----------------------------------------------------------------------
" run wsl command
"----------------------------------------------------------------------
function! s:system_wsl(cmd)
	if s:windows == 0
		call s:errmsg("for windows only")
		return ''
	endif
	let root = ($SystemRoot == '')? 'C:/Windows' : $SystemRoot
	let t1 = root . '/system32/wsl.exe'
	let t2 = root . '/sysnative/wsl.exe'
	let tt = executable(t1)? t1 : (executable(t2)? t2 : '')
	if tt == ''
		call s:errmsg("not find wsl in your system")
		return ''
	endif
	let cmd = shellescape(substitute(tt, '\\', '\/', 'g'))
	let dist = get(g:, 'cppman_wsl_dist', '')
	let cmd = (dist == '')? cmd : (cmd .. ' -d ' .. shellescape(dist))
	return s:system(cmd .. ' ' .. a:cmd)
endfunc


"----------------------------------------------------------------------
" run msys cmd
"----------------------------------------------------------------------
function! s:system_msys(cmd)
	if s:windows == 0
		call s:errmsg("for windows only")
		return ''
	endif
	let msys = get(g:, 'cppman_msys_home', '')
	if msys == ''
		call s:errmsg("g:cppman_msys_home is empty")
		return ''
	endif
	let msys = tr(msys, "\\", '/')
	if !isdirectory(msys)
		call s:errmsg("msys does not exist in " .. msys)
		return ''
	endif
    let last = strpart(msys, strlen(msys) - 1, 1)
	let name = (last == '/' || last == "\\")? msys : (msys .. '/')
	let name = name .. 'usr/bin/bash.exe'
	if !executable(name)
		call s:errmsg("invalid msys path " .. msys)
		return ''
	endif
	let cmd = shellescape(name) .. ' --login -c ' .. shellescape(a:cmd)
	return s:system(cmd)
endfunc


"----------------------------------------------------------------------
" choose best method: 
"----------------------------------------------------------------------
function! s:unix_system(cmd)
	if s:windows == 0
		return s:system(a:cmd)
	endif
	let msys = get(g:, 'cppman_msys_home', '')
	if msys == ''
		return s:system_wsl(a:cmd)
	else
		return s:system_msys(a:cmd)
	endif
endfunc


"----------------------------------------------------------------------
" get page
"----------------------------------------------------------------------
function! s:cppman_get_page(section, page, width)
	let cmd = 'cppman --force-columns=' .. a:width .. ' "' .. a:page .. '"'
	if a:section != 'cppman'
		let cmd = 'MANPAGER=cat MANWIDTH=' .. a:width .. ' man '
		let cmd = cmd .. a:section .. ' "' .. a:page .. '" '
		let cmd = cmd .. ((s:windows)? '' : ' | col -b')
	endif
	" echo "cmd: ".cmd
	return s:unix_system(cmd)
endfunc


"----------------------------------------------------------------------
" get uri
"----------------------------------------------------------------------
function! s:page_uri(section, page)
	if a:section == 'cppman'
		return 'man://cppman/' . a:page
	endif
	let name = a:page .. '.txt'
	return 'man://' .. ((a:section == '')? '.' : a:section) .. '/' .. name
endfunc


"----------------------------------------------------------------------
" extract uri
"----------------------------------------------------------------------
function! s:extract_uri(uri)
	if strpart(a:uri, 0, 6) != 'man://'
		return ['', '']
	endif
	let part = split(strpart(a:uri, 6), '/')
	if len(part) != 2
		return ['', '']
	endif
	let section = (part[0] == '.')? '' : part[0]
	return [section, part[1]]
endfunc


"----------------------------------------------------------------------
" load buffer
"----------------------------------------------------------------------
function! s:load_buffer(section, page, width)
	if a:page == ''
		call s:errmsg('empty page keyword')
		return -1
	endif
	let s:shell_error = 0
	let width = (a:width <= 0)? 80 : a:width
	let content = s:cppman_get_page(a:section, a:page, width)
	if s:shell_error != 0
		echo content
		call s:errmsg('bad return code: ' .. s:shell_error)
		return -1
	endif
	let bid = bufadd(s:page_uri(a:section, a:page)) 
	if bid <= 0
		call s:errmsg('bad buffer number: ' .. bid)
		return -1
	endif
	noautocmd silent! call bufload(bid)
	call setbufvar(bid, "&buftype", 'nofile')
	call setbufvar(bid, "&buflisted", 0)
	call setbufvar(bid, "&swapfile", 0)
	call setbufvar(bid, '&bufhidden', 'hide')
	if a:width > 0
		call setbufvar(bid, "&readonly", 0)
		call setbufvar(bid, "&modifiable", 1)
		noautocmd silent! call deletebufline(bid, 1, '$')
		noautocmd call setbufline(bid, 1, split(content, "\n"))
	endif
	call setbufvar(bid, "&modifiable", 0)
	call setbufvar(bid, "&modified", 0)
	call setbufvar(bid, "&readonly", 1)
	call setbufvar(bid, "cppman_section", a:section)
	call setbufvar(bid, "cppman_page", a:page)
	call setbufvar(bid, "cppman_mode", "yes")
	return bid
endfunc


"----------------------------------------------------------------------
" split window
"----------------------------------------------------------------------
function! cppman#display(mods, section, page)
	if a:page == ''
		call s:errmsg('empty argument')
		return
	endif
	if a:section == '-k'
		echo s:cppman_get_page('-k', a:page, 80)
		return
	endif
	let uri = s:page_uri(a:section, a:page)
	" redraw!
	echo "Loading ..."
	redraw
	let bid = s:load_buffer(a:section, a:page, -1)
	if bid < 0
		return
	endif
	if a:mods == 'tab'
		exec 'tab split'
	elseif get(b:, 'cppman_mode', '') == ''
		let avail = -1
		for i in range(winnr('$'))
			let nr = winbufnr(i + 1)
			if getbufvar(nr, 'cppman_page', '') != ''
				let avail = i + 1
				break
			endif
		endfor
		if avail > 0
			exec avail .. 'wincmd w'
		else
			exec a:mods .. ' split'
		endif
	endif
	silent exec "edit " .. fnameescape(uri)
	let width = winwidth(0) - 2
	let width = (width < 1)? 1 : width
	let limit = get(g:, 'cppman_max_width', 512)
	let bid = s:load_buffer(a:section, a:page, (width > limit)? limit : width)
	setl nonumber norelativenumber signcolumn=no
	setl fdc=0 nofen
	noautocmd setl ft=man
	exec "normal! gg"
	if bid < 0
		return
	endif
	if a:section == 'cppman'
		call s:highlight_cppman()
		setl keywordprg=:Cppman
		setl iskeyword=@,48-57,_,192-255,:,=,~,[,],*,!,<,>
	else
		call s:highlight_man()
		setl keywordprg=:Cppman!
		setl iskeyword=@,48-57,_,192-255,.,-
	endif
	if get(g:, 'cppman_no_keymaps', 0) == 0
		call s:setup_keymaps()
	endif
	exec "normal \<c-g>"
endfunc


"----------------------------------------------------------------------
" command
"----------------------------------------------------------------------
function! s:cppman_cmd(mods, bang, ...)
	if a:0 <= 0
		call s:errmsg('Not enough argument')
		return 
	endif
	if a:bang == ''
		let section = 'cppman'
		if a:0 > 1
			call s:errmsg('Too many arguments')
			return
		endif
		let page = a:1
	else
		if a:0 == 1
			let section = ''
			let page = a:1
			if page == '-k'
				call s:errmsg('Empty keyword')
				return
			endif
		elseif a:0 == 2
			let section = a:1
			let page = a:2
		elseif a:0 > 2
			call s:errmsg('Too many arguments')
			return 
		endif
	endif
	let mods = a:mods
	if mods == ''
		let mods = get(g:, 'cppman_open_mode', '')
		if mods == 'auto' || mods == '<auto>'
			let mods = (winwidth(0) >= 160)? 'vert' : ''
		endif
	endif
	call cppman#display(mods, section, page)
endfunc


"----------------------------------------------------------------------
" command setup
"----------------------------------------------------------------------
command! -bang -nargs=+ Cppman 
			\ call s:cppman_cmd(<q-mods>, '<bang>', <f-args>)


"----------------------------------------------------------------------
" pre get page
"----------------------------------------------------------------------
function! <SID>LoadManPage(cnt)
  if a:cnt == 0
    let old_isk = &iskeyword
    if &ft == 'man'
      setl iskeyword+=(,)
    endif
    let str = expand("<cword>")
    let &l:iskeyword = old_isk
    let page = substitute(str, '(*\(\k\+\).*', '\1', '')
    let sect = substitute(str, '\(\k\+\)(\([^()]*\)).*', '\2', '')
    if match(sect, '^[0-9 ]\+$') == -1
      let sect = ""
    endif
    if sect == page
      let sect = ""
    endif
  else
    let sect = a:cnt
    let page = expand("<cword>")
  endif
  if b:cppman_section == 'cppman'
	  call cppman#display('', 'cppman', page)
  else
	  call cppman#display('', sect, page)
  endif
endfunc


"----------------------------------------------------------------------
" load cppman
"----------------------------------------------------------------------
function! <SID>LoadCppmanPage()
	let name = expand('<cword>')
	call cppman#display('', 'cppman', name)
endfunc


"----------------------------------------------------------------------
" setup_keymaps
"----------------------------------------------------------------------
function! s:setup_keymaps()
	let section = b:cppman_section
	if section == 'cppman'
		noremap <buffer> K :call <SID>LoadCppmanPage()<CR>
		map <buffer> <CR> K
		map <buffer> <C-]> K
		map <buffer> <2-LeftMouse> K
	else
		noremap <buffer> K :call <SID>LoadManPage(0)<cr>
		nnoremap <buffer> <c-]> :call <SID>LoadManPage(v:count)<CR>
		map <buffer> <2-LeftMouse> K
	endif
endfunc


"----------------------------------------------------------------------
" highlight_man
"----------------------------------------------------------------------
function! s:highlight_man()
	if get(b:, 'current_syntax', '') == 'man'
		return
	endif

	let b:current_syntax = 'man'

	syntax clear
	runtime! syntax/ctrlh.vim

	syn case ignore
	syn match  manReference       "\f\+([1-9][a-z]\=)"
	syn match  manTitle	      "^\f\+([0-9]\+[a-z]\=).*"
	syn match  manSectionHeading  "^[a-z][a-z -]*[a-z]$"
	syn match  manSubHeading      "^\s\{3\}[a-z][a-z -]*[a-z]$"
	syn match  manOptionDesc      "^\s*[+-][a-z0-9]\S*"
	syn match  manLongOptionDesc  "^\s*--[a-z0-9-]\S*"
	" syn match  manHistory		"^[a-z].*last change.*$"

	if getline(1) =~ '^[a-zA-Z_]\+([23])'
		syntax include @cCode runtime! syntax/c.vim
		syn match manCFuncDefinition  display "\<\h\w*\>\s*("me=e-1 contained
		syn region manSynopsis start="^SYNOPSIS"hs=s+8 end="^\u\+\s*$"me=e-12 keepend contains=manSectionHeading,@cCode,manCFuncDefinition
	endif


	" Define the default highlighting.
	" Only when an item doesn't have highlighting yet

	hi def link manTitle	    Title
	hi def link manSectionHeading  Statement
	hi def link manOptionDesc	    Constant
	hi def link manLongOptionDesc  Constant
	hi def link manReference	    PreProc
	hi def link manSubHeading      Function
	hi def link manCFuncDefinition Function

endfunc


"----------------------------------------------------------------------
" highlight cppman
"----------------------------------------------------------------------
function! s:highlight_cppman()
	if get(b:, 'current_syntax', '') == 'cppman'
		return
	endif

	let b:current_syntax = 'cppman'

	syntax clear
	syntax case ignore
	syntax match  manReference       "[a-z_:+-\*][a-z_:+-~!\*<>]\+([1-9][a-z]\=)"
	syntax match  manTitle           "^\w.\+([0-9]\+[a-z]\=).*"
	syntax match  manSectionHeading  "^[a-z][a-z_ \-:]*[a-z]$"
	syntax match  manSubHeading      "^\s\{3\}[a-z][a-z ]*[a-z]$"
	syntax match  manOptionDesc      "^\s*[+-][a-z0-9]\S*"
	syntax match  manLongOptionDesc  "^\s*--[a-z0-9-]\S*"

	syntax include @cppCode runtime! syntax/cpp.vim
	syntax match manCFuncDefinition  display "\<\h\w*\>\s*("me=e-1 contained

	syntax region manSynopsis start="^SYNOPSIS"hs=s+8 end="^\u\+\s*$"me=e-12 keepend contains=manSectionHeading,@cppCode,manCFuncDefinition
	syntax region manSynopsis start="^EXAMPLE"hs=s+7 end="^       [^ ]"he=s-1 keepend contains=manSectionHeading,@cppCode,manCFuncDefinition

	" Define the default highlighting.
	" For version 5.7 and earlier: only when not done already
	" For version 5.8 and later: only when an item doesn't have highlighting yet
	if version >= 508 || !exists("did_man_syn_inits")
		hi def link manTitle	    Title
		hi def link manSectionHeading  Statement
		hi def link manOptionDesc	    Constant
		hi def link manLongOptionDesc  Constant
		hi def link manReference	    PreProc
		hi def link manSubHeading      Function
		hi def link manCFuncDefinition Function
	endif

endfunc


"----------------------------------------------------------------------
" testing suit
"----------------------------------------------------------------------
if 1
	" echo s:system_wsl('ls -la /')
	" echo s:cppman_get_page('cppman', 'printf', 80)
	" echo s:load_buffer('', 'printf', 80)
	" echo s:page_uri('', 'printf')
	" echo s:page_uri('3', 'printf')
	" echo s:page_uri('cppman', 'printf')
	" echo s:extract_uri('man://*/printf')
	" echo s:extract_uri('man://3/printf')
	" echo s:extract_uri('man://cppman/printf')
endif


