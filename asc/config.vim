"======================================================================
"
" config.vim - 
"
" Created by skywind on 2018/02/10
" Last Modified: 2018/02/10 12:54:07
"
"======================================================================

"----------------------------------------------------------------------
" syntax config
"----------------------------------------------------------------------
if has('syntax')  
	syntax enable 
	syntax on 
endif


"----------------------------------------------------------------------
" Tab Label config
"----------------------------------------------------------------------
if !exists('g:config_vim_tab_style')
	let g:config_vim_tab_style = 0
endif

" make tabline in terminal mode
function! Vim_NeatTabLine()
	let s = ''
	for i in range(tabpagenr('$'))
		" select the highlighting
		if i + 1 == tabpagenr()
			let s .= '%#TabLineSel#'
		else
			let s .= '%#TabLine#'
		endif

		" set the tab page number (for mouse clicks)
		let s .= '%' . (i + 1) . 'T'

		" the label is made by MyTabLabel()
		let s .= ' %{Vim_NeatTabLabel(' . (i + 1) . ')} '
	endfor

	" after the last tab fill with TabLineFill and reset tab page nr
	let s .= '%#TabLineFill#%T'

	" right-align the label to close the current tab page
	if tabpagenr('$') > 1
		let s .= '%=%#TabLine#%999XX'
	endif

	return s
endfunc

" get a single tab name 
function! Vim_NeatBuffer(bufnr, fullname)
	let l:name = bufname(a:bufnr)
	let bt = getbufvar(a:bufnr, '&buftype')
	if getbufvar(a:bufnr, '&modifiable')
		if l:name == ''
			return '[No Name]'
		elseif bt == 'terminal'
			return '[Terminal]'
		else
			if a:fullname 
				return fnamemodify(l:name, ':p')
			else
				let aname = fnamemodify(l:name, ':p')
				let sname = fnamemodify(aname, ':t')
				if sname == ''
					let test = fnamemodify(aname, ':h:t')
					if test != ''
						return '<'. test . '>'
					endif
				endif
				return sname
			endif
		endif
	else
		let bt = getbufvar(a:bufnr, '&buftype')
		if bt == 'quickfix'
			return '[Quickfix]'
		elseif bt == 'terminal'
			return '[Terminal]'
		elseif l:name != ''
			if a:fullname 
				return '-'.fnamemodify(l:name, ':p')
			else
				return '-'.fnamemodify(l:name, ':t')
			endif
		else
		endif
		return '[No Name]'
	endif
endfunc

" get a single tab label
function! Vim_NeatTabLabel(n)
	let l:buflist = tabpagebuflist(a:n)
	let l:winnr = tabpagewinnr(a:n)
	let l:bufnr = l:buflist[l:winnr - 1]
	let l:fname = Vim_NeatBuffer(l:bufnr, 0)
	let l:buftype = getbufvar(l:bufnr, '&buftype')
	let l:num = a:n
	if g:config_vim_tab_style == 0
		return l:fname
	elseif g:config_vim_tab_style == 1
		return "[".l:num."] ".l:fname
	elseif g:config_vim_tab_style == 2
		return "".l:num." - ".l:fname
	endif
	if getbufvar(l:bufnr, '&modified')
		return "[".l:num."] ".l:fname." +"
	endif
	return "[".l:num."] ".l:fname
endfunc

" get a single tab label in gui
function! Vim_NeatGuiTabLabel()
	let l:num = v:lnum
	let l:buflist = tabpagebuflist(l:num)
	let l:winnr = tabpagewinnr(l:num)
	let l:bufnr = l:buflist[l:winnr - 1]
	let l:fname = Vim_NeatBuffer(l:bufnr, 0)
	if g:config_vim_tab_style == 0
		return l:fname
	elseif g:config_vim_tab_style == 1
		return "[".l:num."] ".l:fname
	elseif g:config_vim_tab_style == 2
		return "".l:num." - ".l:fname
	endif
	if getbufvar(l:bufnr, '&modified')
		return "[".l:num."] ".l:fname." +"
	endif
	return "[".l:num."] ".l:fname
endfunc

" get a label tips
function! Vim_NeatGuiTabTip()
	let tip = ''
	let bufnrlist = tabpagebuflist(v:lnum)
	for bufnr in bufnrlist
		" separate buffer entries
		if tip != ''
			let tip .= " \n"
		endif
		" Add name of buffer
		let name = Vim_NeatBuffer(bufnr, 1)
		let tip .= name
		" add modified/modifiable flags
		if getbufvar(bufnr, "&modified")
			let tip .= ' [+]'
		endif
		if getbufvar(bufnr, "&modifiable")==0
			let tip .= ' [-]'
		endif
	endfor
	return tip
endfunc

" setup new tabline, just %M%t in macvim
set tabline=%!Vim_NeatTabLine()
set guitablabel=%{Vim_NeatGuiTabLabel()}
set guitabtooltip=%{Vim_NeatGuiTabTip()}


function! Tab_MoveLeft()
	let l:tabnr = tabpagenr() - 2
	if l:tabnr >= 0
		exec 'tabmove '.l:tabnr
	endif
endfunc

function! Tab_MoveRight()
	let l:tabnr = tabpagenr() + 1
	if l:tabnr <= tabpagenr('$')
		exec 'tabmove '.l:tabnr
	endif
endfunc

function! s:Filter_Push(desc, wildcard)
	let g:browsefilter .= a:desc . " (" . a:wildcard . ")\t" . a:wildcard . "\n"
endfunc

let g:browsefilter = ''
call s:Filter_Push("All Files", "*")
call s:Filter_Push("C/C++/Object-C", "*.c;*.cpp;*.cc;*.h;*.hh;*.hpp;*.m;*.mm")
call s:Filter_Push("Python", "*.py;*.pyw")
call s:Filter_Push("Text", "*.txt")
call s:Filter_Push("Vim Script", "*.vim")


" restore screen after quitting
if has('unix')
	" disable modifyOtherKeys
	if exists('+t_TI') && exists('+t_TE')
		let &t_TI = ''
		let &t_TE = ''
	endif
	let s:uname = system('uname')
	let s:xterm = 0
	if s:uname =~ "FreeBSD"
		let s:xterm = 1
	endif
	" restore screen after quitting
	if s:xterm != 0
		if &term =~ "xterm"
			let &t_ti="\0337\033[r\033[?47h"
			let &t_te="\033[?47l\0338"
			if has("terminfo")
				let &t_Sf="\033[3%p1%dm"
				let &t_Sb="\033[4%p1%dm"
			else
				let &t_Sf="\033[3%dm"
				let &t_Sb="\033[4%dm"
			endif
		endif
		set restorescreen
	endif
endif


function! Terminal_SwitchTab()
	if has('gui_running')
		return
	endif
	for i in range(10)
		let x = (i == 0)? 10 : i
		exec "noremap <silent><M-".i."> :tabn ".x."<cr>"
		exec "inoremap <silent><M-".i."> <ESC>:tabn ".x."<cr>"
	endfor
	noremap <silent><m-t> :tabnew<cr>
	inoremap <silent><m-t> <ESC>:tabnew<cr>
	noremap <silent><m-w> :tabclose<cr>
	inoremap <silent><m-w> <ESC>:tabclose<cr>
	noremap <m-s> :w<cr>
	inoremap <m-s> <esc>:w<cr>
endfunc

function! Terminal_MetaMode(mode)
	set ttimeout
	if $TMUX != ''
		set ttimeoutlen=30
	elseif &ttimeoutlen > 80 || &ttimeoutlen <= 0
		set ttimeoutlen=80
	endif
	if has('nvim') || has('gui_running')
		return
	endif
	function! s:metacode(mode, key)
		if a:mode == 0
			exec "set <M-".a:key.">=\e".a:key
		else
			exec "set <M-".a:key.">=\e]{0}".a:key."~"
		endif
	endfunc
	for i in range(10)
		call s:metacode(a:mode, nr2char(char2nr('0') + i))
	endfor
	for i in range(26)
		call s:metacode(a:mode, nr2char(char2nr('a') + i))
		call s:metacode(a:mode, nr2char(char2nr('A') + i))
	endfor
	if a:mode != 0
		for c in [',', '.', '/', ';', '[', ']', '{', '}']
			call s:metacode(a:mode, c)
		endfor
		for c in ['?', ':', '-', '_', '+', '=']
			call s:metacode(a:mode, c)
		endfor
	else
		for c in [',', '.', '/', ';', '{', '}']
			call s:metacode(a:mode, c)
		endfor
		for c in ['?', ':', '-', '_', '+', '=', "'"]
			call s:metacode(a:mode, c)
		endfor
	endif
endfunc


function! Terminal_KeyEscape(name, code)
	if has('nvim') || has('gui_running')
		return
	endif
	exec "set ".a:name."=\e".a:code
endfunc


command! -nargs=0 -bang VimMetaInit call Terminal_MetaMode(<bang>0)
command! -nargs=+ VimKeyEscape call Terminal_KeyEscape(<f-args>)


function! Terminal_FnInit(mode)
	if has('nvim') || has('gui_running')
		return
	endif
	if a:mode == 1
		VimKeyEscape <F1> OP
		VimKeyEscape <F2> OQ
		VimKeyEscape <F3> OR
		VimKeyEscape <F4> OS
		VimKeyEscape <S-F1> [1;2P
		VimKeyEscape <S-F2> [1;2Q
		VimKeyEscape <S-F3> [1;2R
		VimKeyEscape <S-F4> [1;2S
		VimKeyEscape <S-F5> [15;2~
		VimKeyEscape <S-F6> [17;2~
		VimKeyEscape <S-F7> [18;2~
		VimKeyEscape <S-F8> [19;2~
		VimKeyEscape <S-F9> [20;2~
		VimKeyEscape <S-F10> [21;2~
		VimKeyEscape <S-F11> [23;2~
		VimKeyEscape <S-F12> [24;2~
	endif
endfunc

function! Terminal_MetaShiftNum()
	let array = [')', '!', '@', '#', '$', '%', '^', '&', '*', '(']
	for i in range(10)
		exec "set <m-" . i . ">=\e" . array[i]
	endfor
endfunc


call Terminal_SwitchTab()

if get(g:, 'asc_skip_meta_fn_setup', 0) == 0
	call Terminal_MetaMode(0)
	call Terminal_FnInit(1)
endif



