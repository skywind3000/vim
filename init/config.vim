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
	let name = bufname(a:bufnr)
	let bt = getbufvar(a:bufnr, '&buftype')
	let xname = getbufvar(a:bufnr, '__asc_bufname', '')
	if xname != ''
		return xname
	endif
	if getbufvar(a:bufnr, '&modifiable')
		if name == ''
			return '[No Name]'
		elseif bt == 'terminal'
			return '[Terminal]'
		else
			if a:fullname 
				return fnamemodify(name, ':p')
			else
				let aname = fnamemodify(name, ':p')
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
		elseif name != ''
			if a:fullname 
				return '-'.fnamemodify(name, ':p')
			else
				return '-'.fnamemodify(name, ':t')
			endif
		else
		endif
		return '[No Name]'
	endif
endfunc

" get a single tab label
function! Vim_NeatTabLabel(n)
	let l:caption = gettabvar(a:n, '__caption', '')
	let l:num = a:n
	let l:modified = 0
	if l:caption == ''
		let l:winnr = tabpagewinnr(a:n)
		let l:buflist = tabpagebuflist(a:n)
		let l:bufnr = l:buflist[l:winnr - 1]
		let l:caption = Vim_NeatBuffer(l:bufnr, 0)
		let l:modified = getbufvar(l:bufnr, '&modified', 0)
	endif
	if g:config_vim_tab_style == 0
		return l:caption
	elseif g:config_vim_tab_style == 1
		return "[".l:num."] ".l:caption
	elseif g:config_vim_tab_style == 2
		return "".l:num." - ".l:caption
	endif
	if l:modified
		return "[".l:num."] ".l:caption." +"
	endif
	return "[".l:num."] ".l:caption
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
set guitablabel=%{Vim_NeatTabLabel(v:lnum)}
set guitabtooltip=%{Vim_NeatGuiTabTip()}



"----------------------------------------------------------------------
" Tab Manipulation
"----------------------------------------------------------------------
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


"----------------------------------------------------------------------
" GVim Dialogs
"----------------------------------------------------------------------
let g:browsefilter = ''
call s:Filter_Push("All Files", "*")
call s:Filter_Push("C/C++/Object-C", "*.c;*.cpp;*.cc;*.h;*.hh;*.hpp;*.m;*.mm")
call s:Filter_Push("Python", "*.py;*.pyw")
call s:Filter_Push("Text", "*.txt")
call s:Filter_Push("Vim Script", "*.vim")


"----------------------------------------------------------------------
" terminal turn
"----------------------------------------------------------------------
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



