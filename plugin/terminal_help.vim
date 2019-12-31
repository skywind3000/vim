"======================================================================
"
" terminal_help.vim -
"
" Created by skywind on 2020/01/01
" Last Modified: 2020/01/01 01:21:33
"
"======================================================================

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
	call win_gotoid(uid)
	if bid > 0
		let name = bufname(bid)
		if name != ''
			let wid = bufwinnr(bid)
			if wid < 0
				exec pos . ' ' . height . 'split'
				exec 'b '. bid
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
		let close = get(g:, 'terminal_close', 1)
		let savedir = getcwd()
		silent execute cd . ' '. fnameescape(expand('%:p:h'))
		let cmd = pos . ' term ' . (close? '++close' : '++noclose') 
		exec cmd . ' ++rows=' . height . ' ' . shell
		silent execute cd . ' '. fnameescape(savedir)
		let t:__terminal_bid__ = bufnr()
		setlocal bufhidden=hide
	endif
	let uid = win_getid()
	noautocmd windo call s:terminal_view(1)
	call win_gotoid(uid)
endfunc

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

nnoremap <silent><m-=> :call TerminalToggle()<cr>
tnoremap <silent><m-=> <c-_>p:call TerminalToggle()<cr>

" set twt=conpty


