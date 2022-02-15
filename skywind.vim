"----------------------------------------------------------------------
" system detection
"----------------------------------------------------------------------
let g:asc_uname = asclib#platform#uname()


"----------------------------------------------------------------------
"- OptImport
"----------------------------------------------------------------------
IncScript site/opt/argtextobj.vim
IncScript site/opt/indent-object.vim
IncScript site/opt/after_object.vim
IncScript site/opt/apc.vim

if has('gui_running')
	IncScript site/opt/hexhigh.vim
endif

runtime! macros/matchit.vim

call after_object#enable(['r', 'R'], '=', ':', '-', '#', ' ', '/', ';', '(', ')')


"----------------------------------------------------------------------
"- Global Settings
"----------------------------------------------------------------------
let g:asyncrun_msys = 'd:/software/msys32'

if isdirectory(g:asyncrun_msys)
	let g:asyncrun_msys = 'd:/Linux'
endif

if has('patch-8.0.0')
	set shortmess+=c
endif

set cpt=.,w,k

if has('patch-8.2.4365')
	set wildoptions+=pum
	set wildmode=longest,full
	" cnoremap <expr> <cr> pumvisible() ? "\<c-y>" : "\<cr>"
	" cnoremap <expr> <esc> pumvisible() ? "\<c-e>" : "\<esc>"
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
	\ 'browser' : '"C:\Program Files\Mozilla Firefox\firefox"',
	\ 'junk' : '~/OneDrive/Documents/notes/VimJunk',
	\ }

call asclib#setting#update(s:settings)

if has('win32') || has('win64') || has('win16') || has('win95')
	call asclib#setting#update(s:settings_win)
	if has('gui_running')

	endif
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
	noremap <silent><space>hw :FileSwitch $VIM_ONEDRIVE/GTD.otl<cr>
	noremap <silent><space>hq :FileSwitch $VIM_ONEDRIVE/quicknote.txt<cr>
	noremap <silent><space>hm :FileSwitch -ft=markdown $VIM_ONEDRIVE/quicknote.md<cr>
	noremap <silent><space>hp :FileSwitch $VIM_ONEDRIVE/personal.gpg<cr>
	if filereadable('c:/drivers/clink/clink.cmd')
		noremap <silent><space>gl :silent !start /b cmd /C c:\drivers\Clink\clink.cmd<cr>
	endif
elseif isdirectory('/mnt/c/Users/Linwei/OneDrive/Documents/notes/Vim') 
	let $VIM_ONEDRIVE = '/mnt/c/Users/Linwei/OneDrive/Documents/notes/Vim'
	noremap <silent><space>hw :FileSwitch $VIM_ONEDRIVE/GTD.otl<cr>
	noremap <silent><space>hq :FileSwitch $VIM_ONEDRIVE/quicknote.txt<cr>
	noremap <silent><space>hm :FileSwitch -ft=markdown $VIM_ONEDRIVE/quicknote.md<cr>
	noremap <silent><space>hp :FileSwitch $VIM_ONEDRIVE/personal.gpg<cr>
endif


"----------------------------------------------------------------------
"- bufferhint
"----------------------------------------------------------------------
if has('patch-8.2.1') || has('nvim-0.4')
	nnoremap <silent>+ :call quickui#tools#list_buffer('FileSwitch tabe')<cr>
else
	nnoremap + :call bufferhint#Popup()<CR>
endif

let g:bufferhint_CustomHighlight = 1
hi! default link KeyHint Statement
hi! default link AtHint Identifier


"----------------------------------------------------------------------
"- miscs
"----------------------------------------------------------------------
let g:cppman_open_mode = '<auto>'

command! -bang -nargs=* -complete=file Make AsyncRun -program=make -once=1 -strip=1 @ <args>

command! -bang -bar -nargs=* Gpush execute 'AsyncRun<bang> -cwd=' .
	  \ fnameescape(FugitiveGitDir()) 'git push' <q-args>
command! -bang -bar -nargs=* Gfetch execute 'AsyncRun<bang> -cwd=' .
	  \ fnameescape(FugitiveGitDir()) 'git fetch' <q-args>

" let g:terminal_shell='cmd /s /k "c:\drivers\clink\clink.cmd inject"'
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
map <leader><F3> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
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



