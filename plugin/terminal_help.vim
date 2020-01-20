"======================================================================
"
" terminal_help.vim -
"
" Created by skywind on 2020/01/01
" Last Modified: 2020/01/01 01:21:33
"
"======================================================================

"----------------------------------------------------------------------
" check compatible
"----------------------------------------------------------------------
if has('patch-8.1.1') == 0 && has('nvim') == 0
	finish
endif


"----------------------------------------------------------------------
" configuration
"----------------------------------------------------------------------

" which key is used to toggle terminal
if !exists('g:terminal_key')
	let g:terminal_key = '<m-=>'
endif

" initialize shell directory
" 0: vim's current working directory (which :pwd returns)
" 1: file path of current file.
" 2: project root of current file.
if !exists('g:terminal_cwd')
	let g:terminal_cwd = 1
endif

" root markers to identify the project root
if !exists('g:terminal_rootmarkers')
	let g:terminal_rootmarkers = ['.git', '.svn', '.project', '.root', '.hg']
endif


"----------------------------------------------------------------------
" Initialize
"----------------------------------------------------------------------
let $VIM_SERVERNAME = v:servername
let $VIM_EXE = v:progpath

let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:script = fnamemodify(s:home . '/../tools/utils', ':p')
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')

" setup PATH for utils
if stridx($PATH, s:script) < 0
	if s:windows == 0
		let $PATH .= ':' . s:script
	else
		let $PATH .= ';' . s:script
	endif
endif

" search for neovim-remote for nvim
let $VIM_NVR = ''
if has('nvim')
	let name = get(g:, 'terminal_nvr', 'nvr')
	if executable(name)
		let $VIM_NVR=name
	endif
endif


"----------------------------------------------------------------------
" internal utils
"----------------------------------------------------------------------

" returns nearest parent directory contains one of the markers
function! s:find_root(name, markers, strict)
	let name = fnamemodify((a:name != '')? a:name : bufname(), ':p')
	let finding = ''
	" iterate all markers
	for marker in a:markers
		if marker != ''
			" search as a file
			let x = findfile(marker, name . '/;')
			let x = (x == '')? '' : fnamemodify(x, ':p:h')
			" search as a directory
			let y = finddir(marker, name . '/;')
			let y = (y == '')? '' : fnamemodify(y, ':p:h:h')
			" which one is the nearest directory ?
			let z = (strchars(x) > strchars(y))? x : y
			" keep the nearest one in finding
			let finding = (strchars(z) > strchars(finding))? z : finding
		endif
	endfor
	if finding == ''
		return (a:strict == 0)? fnamemodify(name, ':h') : ''
	endif
	return fnamemodify(finding, ':p')
endfunc

" returns project root of current file
function! s:project_root()
	let name = expand('%:p')
	return s:find_root(name, g:terminal_rootmarkers, 0)
endfunc


"----------------------------------------------------------------------
" open a new/previous terminal
"----------------------------------------------------------------------
function! TerminalOpen()
	let bid = get(t:, '__terminal_bid__', -1)
	let pos = get(g:, 'terminal_pos', 'rightbelow')
	let height = get(g:, 'terminal_height', 10)
	let succeed = 0
	function! s:terminal_view(mode)
		if a:mode == 0
			let w:__terminal_view__ = winsaveview()
		elseif exists('w:__terminal_view__')
			call winrestview(w:__terminal_view__)
			unlet w:__terminal_view__
		endif
	endfunc
	let uid = win_getid()
	noautocmd windo call s:terminal_view(0)
	noautocmd call win_gotoid(uid)
	if bid > 0
		let name = bufname(bid)
		if name != ''
			let wid = bufwinnr(bid)
			if wid < 0
				exec pos . ' ' . height . 'split'
				exec 'b '. bid
				if mode() != 't'
					if has('nvim')
						startinsert
					else
						exec "normal i"
					endif
				endif
			else
				exec "normal ". wid . "\<c-w>w"
			endif
			let succeed = 1
		endif
	endif
	if has('nvim')
		let cd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	if succeed == 0
		let shell = get(g:, 'terminal_shell', '')
		let close = get(g:, 'terminal_close', 0)
		let savedir = getcwd()
		if g:terminal_cwd == 1
			let workdir = (expand('%') == '')? getcwd() : expand('%:p:h')
			silent execute cd . ' '. fnameescape(workdir)
		elseif g:terminal_cwd == 2
			silent execute cd . ' '. fnameescape(s:project_root())
		endif
		if has('nvim') == 0
			let kill = get(g:, 'terminal_kill', '')
			let cmd = pos . ' term ' . (close? '++close' : '++noclose') 
			let cmd = cmd . ((kill != '')? (' ++kill=' . kill) : '')
			exec cmd . ' ++norestore ++rows=' . height . ' ' . shell
			setlocal nonumber norelativenumber signcolumn=no
		else
			exec pos . ' ' . height . 'split'
			exec 'term ' . shell
			setlocal nonumber norelativenumber signcolumn=no
			startinsert
		endif
		silent execute cd . ' '. fnameescape(savedir)
		let t:__terminal_bid__ = bufnr('')
		setlocal bufhidden=hide
		if get(g:, 'terminal_list', 1) == 0
			setlocal nobuflisted
		endif
	endif
	let x = win_getid()
	noautocmd windo call s:terminal_view(1)
	noautocmd call win_gotoid(uid)    " take care of previous window
	noautocmd call win_gotoid(x)
endfunc


"----------------------------------------------------------------------
" hide terminal
"----------------------------------------------------------------------
function! TerminalClose()
	let bid = get(t:, '__terminal_bid__', -1)
	if bid < 0
		return
	endif
	let name = bufname(bid)
	if name == ''
		return
	endif
	let wid = bufwinnr(bid)
	if wid < 0
		return
	endif
	let sid = win_getid()
	noautocmd windo call s:terminal_view(0)
	call win_gotoid(sid)
	if wid != winnr()
		let uid = win_getid()
		exec "normal ". wid . "\<c-w>w"
		close
		call win_gotoid(uid)
	else
		close
	endif
	let sid = win_getid()
	noautocmd windo call s:terminal_view(1)
	call win_gotoid(sid)
endfunc


"----------------------------------------------------------------------
" toggle open/close
"----------------------------------------------------------------------
function! TerminalToggle()
	let bid = get(t:, '__terminal_bid__', -1)
	let alive = 0
	if bid > 0 && bufname(bid) != ''
		let alive = (bufwinnr(bid) > 0)? 1 : 0
	endif
	if alive == 0
		call TerminalOpen()
	else
		call TerminalClose()
	endif
endfunc


"----------------------------------------------------------------------
" can be calling from internal terminal.
"----------------------------------------------------------------------
function! Tapi_TerminalEdit(bid, arglist)
	let name = (type(a:arglist) == v:t_string)? a:arglist : a:arglist[0]
	let cmd = get(g:, 'terminal_edit', 'tab drop')
	silent exec cmd . ' ' . fnameescape(name)
	return ''
endfunc


"----------------------------------------------------------------------
" enable alt key in terminal vim
"----------------------------------------------------------------------
if has('nvim') == 0 && has('gui_running') == 0
	set ttimeout
	if $TMUX != ''
		set ttimeoutlen=35
	elseif &ttimeoutlen > 80 || &ttimeoutlen <= 0
		set ttimeoutlen=85
	endif
	function! s:meta_code(key)
		if get(g:, 'terminal_skip_key_init', 0) == 0
			exec "set <M-".a:key.">=\e".a:key
		endif
	endfunc
	for i in range(10)
		call s:meta_code(nr2char(char2nr('0') + i))
	endfor
	for i in range(26)
		call s:meta_code(nr2char(char2nr('a') + i))
		call s:meta_code(nr2char(char2nr('A') + i))
	endfor
	for c in [',', '.', '/', ';', '{', '}']
		call s:meta_code(c)
	endfor
	for c in ['?', ':', '-', '_', '+', '=', "'"]
		call s:meta_code(c)
	endfor
	function! s:key_escape(name, code)
		if get(g:, 'terminal_skip_key_init', 0) == 0
			exec "set ".a:name."=\e".a:code
		endif
	endfunc
	call s:key_escape('<F1>', 'OP')
	call s:key_escape('<F2>', 'OQ')
	call s:key_escape('<F3>', 'OR')
	call s:key_escape('<F4>', 'OS')
endif


"----------------------------------------------------------------------
" fast window switching: ALT+SHIFT+HJKL
"----------------------------------------------------------------------
if get(g:, 'terminal_default_mapping', 1)
	noremap <m-H> <c-w>h
	noremap <m-L> <c-w>l
	noremap <m-J> <c-w>j
	noremap <m-K> <c-w>k
	inoremap <m-H> <esc><c-w>h
	inoremap <m-L> <esc><c-w>l
	inoremap <m-J> <esc><c-w>j
	inoremap <m-K> <esc><c-w>k

	if has('terminal') && exists(':terminal') == 2 && has('patch-8.1.1')
		set termwinkey=<c-_>
		tnoremap <m-H> <c-_>h
		tnoremap <m-L> <c-_>l
		tnoremap <m-J> <c-_>j
		tnoremap <m-K> <c-_>k
		tnoremap <m-q> <c-\><c-n>
		tnoremap <m--> <c-_>"0
	elseif has('nvim')
		tnoremap <m-H> <c-\><c-n><c-w>h
		tnoremap <m-L> <c-\><c-n><c-w>l
		tnoremap <m-J> <c-\><c-n><c-w>j
		tnoremap <m-K> <c-\><c-n><c-w>k
		tnoremap <m-q> <c-\><c-n>
		tnoremap <m--> <c-\><c-n>"0pa
	endif

	let s:cmd = 'nnoremap <silent>'.(g:terminal_key). ' '
	exec s:cmd . ':call TerminalToggle()<cr>'

	if has('nvim') == 0
		let s:cmd = 'tnoremap <silent>'.(g:terminal_key). ' '
		exec s:cmd . '<c-_>:call TerminalToggle()<cr>'
	else
		let s:cmd = 'tnoremap <silent>'.(g:terminal_key). ' '
		exec s:cmd . '<c-\><c-n>:call TerminalToggle()<cr>'
	endif
endif


" set twt=conpty


