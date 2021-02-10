

"----------------------------------------------------------------------
"- Quickfix Chinese Convertion
"----------------------------------------------------------------------
function! QuickfixChineseConvert()
   let qflist = getqflist()
   for i in qflist
	  let i.text = iconv(i.text, "gbk", "utf-8")
   endfor
   call setqflist(qflist)
endfunction


"----------------------------------------------------------------------
"- FontBoldOff
"----------------------------------------------------------------------
function! s:FontBoldOff()
	let hid = 1
	while 1
		let hln = synIDattr(hid, 'name')
		if !hlexists(hln) | break | endif
		if hid == synIDtrans(hid) && synIDattr(hid, 'bold')
			let atr = ['underline', 'undercurl', 'reverse', 'inverse', 'italic', 'standout']
			call filter(atr, 'synIDattr(hid, v:val)')
			let gui = empty(atr) ? 'NONE' : join(atr, ',')
			exec 'highlight ' . hln . ' gui=' . gui
		endif
		let hid += 1
	endwhile
endfunc

command! FontBoldOff call s:FontBoldOff()


"----------------------------------------------------------------------
"- GUI Setting
"----------------------------------------------------------------------
function! s:GuiTheme(theme)
	if type(a:theme) == 0
		let l:theme = string(a:theme)
	else
		let l:theme = a:theme
	endif
	if l:theme == '0'
		set guifont=inconsolata:h11
		color desert256
		highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE 
			\ gui=NONE guifg=DarkGrey guibg=NONE
	elseif l:theme == '1'
		set guifont=inconsolata:h11
		color seoul256
	elseif l:theme == '2'
		set guifont=fixedsys:h10
		color seoul256
		FontBoldOff
	endif
endfunc

command! -nargs=1 GuiTheme call s:GuiTheme(<f-args>)


"----------------------------------------------------------------------
" remove signs
"----------------------------------------------------------------------
function! s:GuiSignRemove(...)
	if a:0 == 0 | return | endif
	redir => x
	silent sign place
	redir END
	let lines = split(x, '\n')
	for line in lines
		if line =~ '^\s*line=\d*\s*id=\d*\s*name='
			let name = matchstr(line, '^\s*line=.*name=\zs\w*')
			let id = matchstr(line, '^\s*line=\d*\s*id=\zs\w*')
			for x in range(a:0)
				if name == a:{x + 1}
					silent exec 'sign unplace '.id
				endif
			endfor
		endif
	endfor
endfunc

command! -nargs=+ GuiSignRemove call s:GuiSignRemove(<f-args>)



"----------------------------------------------------------------------
" Update Highlight
"----------------------------------------------------------------------
function! s:GuiThemeHighlight()
	highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE 
		\ gui=NONE guifg=DarkGrey guibg=NONE
	highlight Pmenu guibg=darkgrey guifg=black
endfunc

command! -nargs=0 GuiThemeHighlight call s:GuiThemeHighlight()



"----------------------------------------------------------------------
" GUI detection
"----------------------------------------------------------------------
let g:asc_gui = 0

if has('gui_running')
	let g:asc_gui = 1
elseif has('nvim')
	if exists('g:GuiLoaded')
		if g:GuiLoaded != 0
			let g:asc_gui = 1
		endif
	elseif exists('*nvim_list_uis') && len(nvim_list_uis()) > 0
		let uis = nvim_list_uis()[0]
		let g:asc_gui = get(uis, 'ext_termcolors', 0)? 0 : 1
	elseif exists("+termguicolors") && (&termguicolors) != 0
		let g:asc_gui = 1
	endif
endif


"----------------------------------------------------------------------
"- GUI Setting
"----------------------------------------------------------------------
if has('gui_running')
	set guioptions-=L
	set mouse=a
	set showtabline=2
	set laststatus=2
	set number
	set t_Co=256
	let g:seoul256_background = 236
	let g:asc_gui = 1
	if has('win32') || has('win64') || has('win16') || has('win95')
		language messages en
		set langmenu=en_US
		set guifont=inconsolata:h11
		"set guifont=fixedsys
		"au QuickfixCmdPost make call QuickfixChineseConvert()
		let g:config_vim_tab_style = 3
		"color desert256
		try
			color seoul256
		catch
		endtry
		set guioptions-=t
		set guioptions=egrmT
	elseif has('gui_macvim')
		color seoul256
		set guioptions=egrm
	endif
	highlight Pmenu guibg=darkgrey guifg=black
else
	set t_Co=256 t_md=
endif

if has('nvim') && (has('win32') || has('win64'))
	set guioptions-=L
	set mouse=a
	set showtabline=2
	set laststatus=2
	set number
	set t_Co=256
	let g:config_vim_tab_style = 3
endif


"----------------------------------------------------------------------
" Purify NVim-Qt
"----------------------------------------------------------------------
function! s:GuiPureNVim()
	if has('nvim') && g:asc_gui
		call rpcnotify(1, 'Gui', 'Option', 'Tabline', 0)
		call rpcnotify(0, "Gui", "Option", "Popupmenu", 0)
	endif
endfunc

command! -nargs=0 GuiPureNVim call s:GuiPureNVim()


"----------------------------------------------------------------------
"- Menu Setting
"----------------------------------------------------------------------
amenu 80.10 B&uild.&Run<TAB>F5 :VimExecute run<cr>
amenu 80.20 B&uild.E&xecute<TAB>F6 :VimExecute filename<cr>
amenu 80.25 B&uild.-s1- :
amenu 80.30 B&uild.&Gcc<TAB>F9 :AsyncRun gcc<cr>
amenu 80.35 B&uild.&Emake<Tab>F7 :AsyncRun emake<cr>
amenu 80.40 B&uild.GNU\ &Make :AsyncRun make<cr>
amenu 80.42 B&uild.-s2- :
amenu 80.45 B&uild.User\ Tool\ 1 :VimTool 1<cr>
amenu 80.50 B&uild.User\ Tool\ 2 :VimTool 2<cr>
amenu 80.55 B&uild.User\ Tool\ 3 :VimTool 3<cr>
amenu 80.60 B&uild.User\ Tool\ 4 :VimTool 4<cr>
amenu 80.65 B&uild.User\ Tool\ 5 :VimTool 5<cr>
amenu 80.70 B&uild.User\ Tool\ 6 :VimTool 6<cr>
amenu 80.75 B&uild.User\ Tool\ 7 :VimTool 7<cr>
amenu 80.80 B&uild.User\ Tool\ 8 :VimTool 8<cr>
amenu 80.85 B&uild.User\ Tool\ 9 :VimTool 9<cr>
amenu 80.90 B&uild.User\ Tool\ 0 :VimTool 0<cr>

amenu PopUp.-s9- :
amenu PopUp.Open\ &Header :call Open_HeaderFile(2)<cr>
amenu PopUp.Grep\ &Project :GrepCode! <C-R>=expand("<cword>")<cr><cr>
amenu PopUp.Grep\ H&ere :GrepCode <C-R>=expand("<cword>")<cr><cr>
amenu PopUp.-s10- :
amenu PopUp.Search\ &Symbol :VimScope s <C-R>=expand("<cword>")<CR><CR>
amenu PopUp.Search\ &Defininition :VimScope g <C-R>=expand("<cword>")<CR><CR>
amenu PopUp.Functions\ &Called by :VimScope d <C-R>=expand("<cword>")<CR><CR>
amenu PopUp.Functions\ C&alling :VimScope c <C-R>=expand("<cword>")<CR><CR>
amenu PopUp.Search\ &String :VimScope t <C-R>=expand("<cword>")<CR><CR>
amenu PopUp.Search\ Pa&ttern :VimScope e <C-R>=expand("<cword>")<CR><CR>
amenu PopUp.Search\ &File :VimScope f <C-R>=expand("<cfile>")<CR><CR>
amenu PopUp.Search\ &Include :VimScope i <C-R>=expand("<cfile>")<CR><CR>



