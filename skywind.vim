"----------------------------------------------------------------------
"- Global Settings
"----------------------------------------------------------------------
let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let &tags = './.tags;,.tags,' . expand('~/.vim/tags/standard.tags')

filetype plugin indent on
set hlsearch
set incsearch
set wildmenu
set ignorecase
set cpo-=<
noremap <tab>/ :emenu <C-Z>
" noremap <c-n>  :emenu <C-Z>
set lazyredraw
set errorformat+=[%f:%l]\ ->\ %m,[%f:%l]:%m
command! -nargs=1 VimImport exec 'so '.s:home.'/'.'<args>'
command! -nargs=1 VimLoad exec 'set rtp+='.s:home.'/'.'<args>'

let g:vimmake_open = 6
let g:asyncrun_open = 6

highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE 
	\ gui=NONE guifg=DarkGrey guibg=NONE

call Backup_Directory()

let g:ycm_goto_buffer_command = 'new-or-existing-tab'

if has('patch-7.4.500') || v:version >= 800
	if !has('nvim')
		set cryptmethod=blowfish2
	endif
endif


"----------------------------------------------------------------------
" builtin terminal settings 
"----------------------------------------------------------------------
if has('nvim')
	set guicursor=
elseif (!has('gui_running')) && has('terminal') && has('patch-8.0.1200')
	let g:termcap_guicursor = &guicursor
	let g:termcap_t_RS = &t_RS
	let g:termcap_t_SH = &t_SH
	set guicursor=
	set t_RS=
	set t_SH=
endif


"----------------------------------------------------------------------
"- Autocmds
"----------------------------------------------------------------------
augroup SkywindGroup
	au!
	" au User AsyncRunStart call asyncrun#quickfix_toggle(6, 1)
	" au User VimMakeStart call vimmake#toggle_quickfix(6, 1)
	au User VimScope call vimmake#toggle_quickfix(6, 1)
	au BufNewFile,BufRead *.as setlocal filetype=actionscript
	au BufNewFile,BufRead *.pro setlocal filetype=prolog
	au BufNewFile,BufRead *.es setlocal filetype=erlang
	au BufNewFile,BufRead *.asc setlocal filetype=asciidoc
	au BufNewFile,BufRead *.vl setlocal filetype=verilog
	au FileType python setlocal shiftwidth=4 tabstop=4 noexpandtab
	au FileType lisp setlocal ts=8 sts=2 sw=2 et
	au FileType scala setlocal sts=4 sw=4 noet
	au FileType haskell setlocal et
	au FileType c,cpp call s:language_cpp()
augroup END


"----------------------------------------------------------------------
" languages
"----------------------------------------------------------------------
function s:language_cpp()
	" syntax match cCustomFunc /\w\+\s*(/me=e-1,he=e-1
	" highlight def link cCustomFunc Function
	setlocal commentstring=//\ %s
endfunc



"----------------------------------------------------------------------
" fold restore
"----------------------------------------------------------------------
function! SkywindFoldRestore(enable)
	if a:enable != 0
		augroup SkywindViewRestore
			au! 
			au BufWrite,VimLeave * silent! mkview
			au BufRead * silent! loadview
		augroup END
	else
		augroup SkywindViewRestore
			au!
		augroup END
	endif
endfunc


"----------------------------------------------------------------------
" config
"----------------------------------------------------------------------
let s:settings = {  
	\ 'cygwin': 'd:/linux',
	\ 'zeal': 'D:\Program Files\zeal-portable-0.5.0-windows-x86\zeal.exe',
	\ }

let s:settings_win = {
	\ 'emacs': 'd:/dev/emacs/bin/runemacs.exe',
	\ 'gdb' : 'd:/dev/mingw32/bin/gdb.exe',
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
	noremap <space>hw :FileSwitch tabe e:/svn/doc/linwei/GTD.otl<cr>
else
endif


"----------------------------------------------------------------------
"- Return last position
"----------------------------------------------------------------------
autocmd BufReadPost *
	\ if line("'\"") > 1 && line("'\"") <= line("$") |
	\	 exe "normal! g`\"" |
	\ endif



"----------------------------------------------------------------------
"- Vimmake
"----------------------------------------------------------------------
let g:vimmake_run_guess = ['go']
let g:vimmake_ftrun = {}
let g:vimmake_ftrun['make'] = 'make -f'
let g:vimmake_ftrun['zsh'] = 'zsh'
let g:vimmake_ftrun['erlang'] = 'escript'
let g:vimmake_ftmake = {}
let g:vimmake_ftmake['go'] = 'go build -o "$(VIM_FILEDIR)/$(VIM_FILENOEXT).exe" "$(VIM_FILEPATH)" '

let g:vimmake_extrun = {'hs': 'runghc', 'lisp': 'sbcl --script'}

let g:vimmake_extrun['scala'] = 'scala'
let g:vimmake_extrun['es'] = 'escript'
let g:vimmake_extrun['erl'] = 'escript'
let g:vimmake_extrun['clj'] = 'clojure'
let g:vimmake_extrun['hs'] = 'runghc'

if has('win32') || has('win64') || has('win16') || has('win95')
	let g:vimmake_extrun['scm'] = "d:\\linux\\bin\\guile.exe"
	let g:vimmake_extrun['io'] = "d:\\dev\\IoLanguage\\bin\\io.exe"
	let g:vimmake_extrun['pro'] = "start d:\\dev\\swipl\\bin\\swipl-win.exe -s"
	let g:vimmake_extrun['pl'] = "start d:\\dev\\swipl\\bin\\swipl-win.exe -s"
	let g:vimmake_build_encoding = 'gbk'
	let g:asyncrun_encs = 'gbk'
	let cp = "d:/dev/scala/scala-2.11.6/lib/scala-actors-2.11.0.jar;"
	let cp.= "d:/dev/scala/scala-2.11.6/lib/akka-actor_2.11-2.3.4.jar"
	let g:vimmake_extrun['scala'] = 'scala'
	"let g:vimmake_extrun['scala'].= ' -cp '.fnameescape(cp)
	let g:vimmake_extrun['gv'] = 'd:/dev/tools/graphviz/bin/dotty.exe'
	let g:vimmake_extrun['dot'] = 'd:/dev/tools/graphviz/bin/dotty.exe'
	let g:vimmake_ftrun['dot'] = 'd:/dev/tools/graphviz/bin/dotty.exe'
	let g:vimmake_ftrun['verilog'] = 'd:/dev/iverilog/bin/iverilog.exe'
else
	if executable('clisp')
		let g:vimmake_extrun['lisp'] = 'clisp'
	elseif executable('sbcl')
		let g:vimmake_extrun['list'] = 'sbcl --script'
	endif
	if executable('swipl')
		let g:vimmake_extrun['pro'] = 'swipl -s'
	endif
endif

if has('win32') || has('win64') || has('win16') || has('win95')
	let g:vimmake_cflags = ['-O3', '-lwinmm', '-lstdc++', '-lgdi32', '-lws2_32', '-msse3']
else
	let g:vimmake_cflags = ['-O3', '-lstdc++']
	runtime ftplugin/man.vim
	nnoremap K :Man <cword><CR>
	let g:ft_man_open_mode = 'vert'
endif

if has('nvim')
	let g:asyncrun_trim = 1
	let g:vimmake_build_trim = 1
endif

let g:vimmake_mode = {}

for s:i in range(10)
	if !has_key(g:vimmake_mode, s:i)
		let g:vimmake_mode[s:i] = 'async'
	endif
	if !has_key(g:vimmake_mode, 'c'.s:i)
		let g:vimmake_mode['c'.s:i] = 'async'
	endif
endfor





"----------------------------------------------------------------------
"- OptImport
"----------------------------------------------------------------------
" VimImport site/echofunc.vim
VimImport site/argtextobj.vim
VimImport site/indent-object.vim
VimImport site/calendar.vim
"VimImport site/hilinks.vim

if has('gui_running')
	VimImport site/hexhigh.vim
endif



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
"- neocomplete
"----------------------------------------------------------------------
if 0
	let g:acp_enableAtStartup = 0
	" Use neocomplete.
	let g:neocomplete#enable_at_startup = 1
	" Use smartcase.
	let g:neocomplete#enable_smart_case = 1
	" Set minimum syntax keyword length.
	let g:neocomplete#sources#syntax#min_keyword_length = 3
	let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'

	" Define dictionary.
	let g:neocomplete#sources#dictionary#dictionaries = {
				\ 'default' : '',
				\ 'vimshell' : $HOME.'/.vimshell_hist',
				\ 'scheme' : $HOME.'/.gosh_completions'
				\ }

	" Define keyword.
	if !exists('g:neocomplete#keyword_patterns')
		let g:neocomplete#keyword_patterns = {}
	endif
	let g:neocomplete#keyword_patterns['default'] = '\h\w*'

	" Plugin key-mappings.
	inoremap <expr><C-g>     neocomplete#undo_completion()
	"inoremap <expr><C-l>     neocomplete#complete_common_string()

	" Recommended key-mappings.
	" <CR>: close popup and save indent.
	inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
	function! s:my_cr_function()
		return neocomplete#close_popup() . "\<CR>"
		" For no inserting <CR> key.
		"return pumvisible() ? neocomplete#close_popup() : "\<CR>"
	endfunction
	" <TAB>: completion.
	inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
	" <C-h>, <BS>: close popup and delete backword char.
	"inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
	inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
	inoremap <expr><C-y>  neocomplete#close_popup()
	inoremap <expr><C-e>  neocomplete#cancel_popup()
	" Close popup by <Space>.
	inoremap <expr><Space> pumvisible() ? neocomplete#close_popup() : "\<Space>"

	" AutoComplPop like behavior.
	let g:neocomplete#enable_auto_select = 1

	" Shell like behavior(not recommended).
	set completeopt+=longest
	let g:neocomplete#enable_auto_select = 1
	let g:neocomplete#disable_auto_complete = 1
	inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<C-x>\<C-u>"

	" Enable omni completion.
	autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
	autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
	autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
	autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
	autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

	" Enable heavy omni completion.
	if !exists('g:neocomplete#sources#omni#input_patterns')
		let g:neocomplete#sources#omni#input_patterns = {}
	endif

	"let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
	"let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
	"let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'

	" For perlomni.vim setting.
	" https://github.com/c9s/perlomni.vim
	let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'
endif




"----------------------------------------------------------------------
"- bufferhint
"----------------------------------------------------------------------
nnoremap - :call bufferhint#Popup()<CR>
nnoremap <leader>p :call bufferhint#LoadPrevious()<CR>

let g:bufferhint_CustomHighlight = 1
hi! default link KeyHint Statement
hi! default link AtHint Identifier



"----------------------------------------------------------------------
" Enable vim-diff-enhanced (Christian Brabandt)
"----------------------------------------------------------------------
function! EnableEnhancedDiff()
	let &diffexpr='EnhancedDiff#Diff("git diff", "--diff-algorithm=patience")'
endfunc

if executable('git')
	let &diffexpr='EnhancedDiff#Diff("git diff", "--diff-algorithm=patience")'
endif


command! -bang -nargs=* -complete=file Make VimMake -program=make @ <args>



"----------------------------------------------------------------------
" color scheme
"----------------------------------------------------------------------
map <leader><F3> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
	\ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
	\ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

augroup ThemeUpdateGroup
	au!
	"au Syntax netrw call s:netrw_highlight()
	"au ColorScheme * GuiThemeHighlight
augroup END


let g:solarized_termcolors=256


if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
          \ | wincmd p | diffthis
endif

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


