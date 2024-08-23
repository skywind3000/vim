"----------------------------------------------------------------------
" startup
"----------------------------------------------------------------------
let g:asc_uname = asclib#platform#uname()
let s:scripthome = fnamemodify(resolve(expand('<sfile>:p')), ':h')
exec 'set rtp+='. fnameescape(expand('<sfile>:p:h') . '/site/package')


"----------------------------------------------------------------------
" OptImport
"----------------------------------------------------------------------
" IncScript site/opt/argtextobj.vim
IncScript site/opt/angry.vim
IncScript site/opt/indent-object.vim
IncScript site/opt/after_object.vim
IncScript site/opt/apc.vim

let g:asynctasks_complete = 1

if has('gui_running')
	IncScript site/opt/hexhigh.vim
endif

call module#drivers#install()

call after_object#enable(['r', 'R'], '=', ':', '-', '#', ' ', '/', ';', '(', ')')



"----------------------------------------------------------------------
"- asyncrun / asynctasks
"----------------------------------------------------------------------
let g:asyncrun_msys = ''
for msys in ['d:/Linux', 'd:/software/msys32']
	if isdirectory(msys) && executable(msys . '/usr/bin/bash.exe')
		let g:asyncrun_msys = msys
		break
	endif
endfor

let g:asyncrun_show_time = 1
let g:asyncrun_rootmarks = ['.project', '.root', '.git', '.git', '.svn']
let g:asyncrun_rootmarks += ['.hg', '.obsidian']
let g:asclib_path_rootmarks = g:asyncrun_rootmarks

if has('patch-8.0.0')
	set shortmess+=c
endif

set cpt=.,w,k

if has('patch-8.2.4500')
	set wildoptions+=pum,fuzzy
	set wildmode=longest,full
	" cnoremap <expr> <cr> pumvisible() ? "\<c-y>" : "\<cr>"
	" cnoremap <expr> <esc> pumvisible() ? "\<c-e>" : "\<esc>"
endif

if has('patch-9.0.648') || has('nvim-0.9.0')
	set splitkeep=screen
endif

if executable('playwav.exe')
	let f1 = 'c:/share/vim/tools/sample/sample-6.wav'
	let f2 = 'c:/share/support/site/res/samples/sample-6.wav'
	for f in [f1, f2]
		if filereadable(f)
			let t = printf('silent !start playwav.exe "%s" 200', f)
			let g:asyncrun_exit = t
			break
		endif
	endfor
endif


"----------------------------------------------------------------------
" term compatible
"----------------------------------------------------------------------
if asclib#platform#has('win')
	if has('nvim') == 0 && has('gui_running') == 0
		" fix: https://github.com/vim/vim/issues/13956
		exec 'set t_ut='
	endif
elseif asclib#platform#has_wsl()
	" fixed: vim will enter replace mode in wsl with cmd window
	exec 'set t_u7='
endif


"----------------------------------------------------------------------
" term keymap
"----------------------------------------------------------------------
let g:altmeta_extension = get(g:, 'altmeta_extension', [])
" let g:altmeta_extension += [['<m-\>', "\e\\"]]
" let g:altmeta_extension += [['<m-[>', "\e["]]
" let g:altmeta_extension += [['<m-]>', "\e]"]]

if !has('nvim')
	" exec "set <m-[>=\e["
endif


"----------------------------------------------------------------------
" asclib settings
"----------------------------------------------------------------------
let s:settings = {  
	\ 'cygwin': 'd:/linux',
	\ 'zeal': 'D:\Program Files\zeal-portable\zeal.exe',
	\ }

let s:settings_win = {
	\ 'emacs': 'd:/dev/emacs/bin/runemacs.exe',
	\ 'gdb' : 'd:/dev/mingw32/bin/gdb.exe',
	\ 'browser' : '"C:\Program Files\Mozilla Firefox\firefox" --new-tab',
	\ 'junk' : '~/OneDrive/Documents/notes/VimJunk',
	\ }

let test = '~/ODrive/OneDrive/Documents/notes/VimJunk'
if isdirectory(expand(test))
	let s:settings_win.junk = test
endif

call asclib#setting#update(s:settings)


"----------------------------------------------------------------------
" system
"----------------------------------------------------------------------
if has('win32') || has('win64') || has('win16') || has('win95')
	call asclib#setting#update(s:settings_win)
endif


"----------------------------------------------------------------------
" QuickMenu
"----------------------------------------------------------------------
call quickmenu#current(2)

if has('win32') || has('win64') || has('win16') || has('win95')
	call quickmenu#append('# Help', '')
	call quickmenu#append('Win32 Help', 'call menu#WinHelp("d:/dev/help/win32.hlp")', 'Looking up Win32 API')
	call quickmenu#append('MSDN of VC6', 'call menu#WinHelp("d:/dev/help/chm/vc.chm")', 'MSDN')
	call quickmenu#append('Python2 Help', 'call menu#WinHelp("d:/dev/help/chm/python2713.chm")', 'Python 2 Document')
	call quickmenu#append('Python3 Help', 'call menu#WinHelp("d:/dev/help/chm/python362.chm")', 'Python 3 Document')
	call quickmenu#append('Open Cygwin', 'call asclib#utils#terminal("mintty", "bash -i", 0)', 'open cygwin in current directoy')
	call quickmenu#append('Open Bash', 'call asclib#wsl_bash("")', 'open bash for windows 10 in current directory')
	call quickmenu#append('Open PowerShell', '!start powershell', 'open bash for windows 10 in current directory')
	call quickmenu#append('Switch color', 'call SkywindSwitchColor()', 'switch current color scheme')
endif


"----------------------------------------------------------------------
" keymaps 
"----------------------------------------------------------------------
if has('win32') || has('win16') || has('win64') || has('win95')
	let $VIM_ONEDRIVE = $HOME . '/OneDrive/Documents/notes/Vim'
	let test = $HOME . '/ODrive/OneDrive/Documents/notes/Vim'
	if isdirectory(test)
		let $VIM_ONEDRIVE = test
	endif
	nnoremap <silent><space>hw :FileSwitch e:\lab\workshop\README.md<cr>
	nnoremap <silent><space>hW :FileSwitch e:\Kingsoft\git\bbnet\README.md<cr>
	nnoremap <silent><space>hq :FileSwitch $VIM_ONEDRIVE/quicknote.md<cr>
	nnoremap <silent><space>hm :FileSwitch -ft=markdown $VIM_ONEDRIVE/quicknote.md<cr>
	nnoremap <silent><space>hp :FileSwitch $VIM_ONEDRIVE/personal.gpg<cr>
	if filereadable('c:/drivers/clink/clink.cmd')
		nnoremap <silent><space>gl :silent AsyncRun -mode=term -pos=hide -cwd=$(VIM_FILEDIR) c:\drivers\Clink\clink.cmd<cr>
	endif
elseif isdirectory('/mnt/c/Users/Linwei/OneDrive/Documents/notes/Vim') 
	let $VIM_ONEDRIVE = '/mnt/c/Users/Linwei/OneDrive/Documents/notes/Vim'
	let test = '/mnt/c/Users/Linwei/ODrive/OneDrive/Documents/notes/Vim'
	if isdirectory(test)
		let $VIM_ONEDRIVE = test
	endif
	nnoremap <silent><space>hw :FileSwitch ~/github/workshop/README.md<cr>
	nnoremap <silent><space>hq :FileSwitch $VIM_ONEDRIVE/quicknote.md<cr>
	nnoremap <silent><space>hm :FileSwitch -ft=markdown $VIM_ONEDRIVE/quicknote.md<cr>
	nnoremap <silent><space>hp :FileSwitch $VIM_ONEDRIVE/personal.gpg<cr>
endif

nnoremap <silent><space>hf :FileSwitch ~/.vim/test.comp<cr>



"----------------------------------------------------------------------
"- miscs
"----------------------------------------------------------------------
let g:cppman_open_mode = '<auto>'

command! -bang -nargs=* -complete=file Make AsyncRun -program=make -once=1 -strip=1 @ <args>

command! -bang -bar -nargs=* Gpush execute 'AsyncRun<bang> -cwd=' .
	  \ fnameescape(FugitiveGitDir()) '-post=echo\ "done" git push' <q-args>
command! -bang -bar -nargs=* Gfetch execute 'AsyncRun<bang> -cwd=' .
	  \ fnameescape(FugitiveGitDir()) '-post=echo\ "done" git fetch' <q-args>

set timeoutlen=2000

command! Ghistory :0Gclog! -- %

" set listchars=tab:»\ ,trail:.,extends:>,precedes:<


"----------------------------------------------------------------------
"- OmniCpp
"----------------------------------------------------------------------
let OmniCpp_NamespaceSearch = 1
let OmniCpp_GlobalScopeSearch = 1
let OmniCpp_ShowAccess = 1 
let OmniCpp_ShowPrototypeInAbbr = 1
let OmniCpp_MayCompleteDot = 1  
let OmniCpp_MayCompleteArrow = 1 
let OmniCpp_MayCompleteScope = 1
let OmniCpp_DefaultNamespaces = ["std", "_GLIBCXX_STD"]



"----------------------------------------------------------------------
" color scheme
"----------------------------------------------------------------------
nmap <leader><F3> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
	\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
	\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

let g:solarized_termcolors=256

nnoremap <leader><F1> :call Tools_ProfileStart('~/.vim/profile.log')<cr>
nnoremap <leader><F2> :call Tools_ProfileStop()<cr>


"----------------------------------------------------------------------
" color scheme
"----------------------------------------------------------------------
let s:colors = ['biogoo', 'calmbreeze', 'dawn', 'dejavu', 'eclipse2', 'paradox', 'gaea', 'github', 'greyhouse', 'habiLight', 'imperial']
let s:colors += ['mayansmoke', 'mickeysoft', 'newspaper', 'nuvola', 'oceanlight', 'peaksea', 'pyte', 'summerfruit256', 'tomorrow']
let s:colors += ['monokai-vim']

function! SkywindSwitchColor()
	call asclib#color_switch(s:colors)
endfunc


"----------------------------------------------------------------------
" quickui
"----------------------------------------------------------------------
let g:quickui_tags_list = {
			\ 'python': '--python-kinds=fmc --language-force=Python',
			\ }

let g:quickui_tags_indent = {
			\ 'm': '  ',
			\ }

let g:quickui_color_scheme = 'papercol-light'

let g:navigator_hide_cursor = 0
let g:navigator_display_path = 1


"----------------------------------------------------------------------
" completion
"----------------------------------------------------------------------
let g:apc_enable_ft = get(g:, 'apc_enable_ft', {})
let g:apc_enable_ft.text = 1
let g:apc_enable_ft.markdown = 1
let g:apm_enable_ft = g:apc_enable_ft


let g:ycm_filetype_blacklist = get(g:, 'ycm_filetype_blacklist', {})
let g:ycm_filetype_blacklist['lua'] = 1
" let g:ycm_filetype_blacklist['text'] = 1
" let g:ycm_filetype_blacklist['markdown'] = 1

let g:ycm_collect_identifiers_from_tags_files  = 1
" let g:ycm_filetype_blacklist = {}
" let g:ycm_filetype_whitelist['text'] = 1


if has('win32') || has('win16') || has('win64') || has('win95')
	let g:vimwiki_path = '~/OneDrive/Documents/notes/VimWiki'
	let test = '~/ODrive/OneDrive/Documents/notes/VimWiki'
	if isdirectory(expand(test))
		let g:vimwiki_path = test
	endif
	if has('gui_running') && v:version >= 801
		if !has('nvim')
			set tbis=large
		endif
	endif
	if executable('c:/drivers/clink/clink.cmd')
		let g:terminal_shell='cmd /s /k "c:\drivers\clink\clink.cmd inject"'
	endif
endif


"----------------------------------------------------------------------
" misc
"----------------------------------------------------------------------
let g:tools_align_width = 22


