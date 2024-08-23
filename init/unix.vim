" just another setup file yet, some handy stuff


"----------------------------------------------------------------------
" Better setup for VIM 7.0 and later
"----------------------------------------------------------------------
filetype plugin indent on
set hlsearch
set incsearch
set wildmenu
set wcm=<C-Z>
set ignorecase
set smartcase
set switchbuf=useopen,usetab,newtab
set lazyredraw
set vop=folds,cursor
set cpo-=<
set fdm=indent
set foldlevel=99
set history=2000
set tags=./.tags;,.tags
set viminfo+=!
set splitright
set viewdir=~/.vim/view
set errorformat=%.\ %#-->\ %f:%l:%c,%f(%l):%m,%f:%l:%c:%m,%f:%l:%m
set whichwrap=b,s,<,>,[,]
set browsedir=buffer
set keymodel=
set selection=inclusive


if exists('+breakindent')
	set breakindent
endif

if has('patch-8.1.1300')
	set shortmess-=S
endif

nnoremap <tab>/ :emenu <C-Z>


"----------------------------------------------------------------------
" Include Scripts
"----------------------------------------------------------------------
let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')

" IncScript / IncRtp
if !exists(':IncScript')
	command! IncScript -nargs=1 exec 'so ' . fnameescape(s:home .'/<args>')
endif

if !exists(':IncRtp')
	command! -nargs=1 IncRtp exec 'set rtp+='.s:home.'/'.'<args>'
endif


"----------------------------------------------------------------------
" turn latest features
"----------------------------------------------------------------------

" Enable vim-diff-enhanced (Christian Brabandt)
if has('patch-8.2.0001')
	set diffopt+=internal,algorithm:patience
	set diffopt+=indent-heuristic
endif

" complete option
if has('patch-8.0.1000')
	set completeopt=menu,menuone,noselect
else
	set completeopt=menu,menuone
endif

" new blowfish2 
if has('patch-7.4.500') || v:version >= 800
	if !has('nvim')
		set cryptmethod=blowfish2
	endif
endif

" enable new-style cursorline (for numbers only)
if exists('+cursorlineopt')
	set cursorlineopt=number cursorline
endif

" setup shell 
if &shell =~# 'fish'
	set shell=sh
endif


"----------------------------------------------------------------------
" fixed cursor shaping compatible issues for some terminals
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

" restore last position
autocmd BufReadPost *
	\ if line("'\"") > 1 && line("'\"") <= line("$") |
	\	 exe "normal! g`\"" |
	\ endif


"----------------------------------------------------------------------
" use ~/.vim/tmp as backup directory
"----------------------------------------------------------------------
if get(g:, 'asc_no_backup', 0) == 0
	set backup
	set writebackup
	set backupdir=~/.vim/tmp
	set backupext=.bak
	set noswapfile
	set noundofile
	let path = expand('~/.vim/tmp')
	if isdirectory(path) == 0
		silent! call mkdir(path, 'p', 0755)
	endif
endif


"----------------------------------------------------------------------
" autocmd group
"----------------------------------------------------------------------
augroup AscUnixGroup
	au!
	au FileType * call s:language_setup()
	au User VimScope call vimmake#toggle_quickfix(6, 1)
	au BufNewFile,BufRead *.as setlocal filetype=actionscript
	au BufNewFile,BufRead *.pro setlocal filetype=prolog
	au BufNewFile,BufRead *.es setlocal filetype=erlang
	au BufNewFile,BufRead *.asc setlocal filetype=asciidoc
	au BufNewFile,BufRead *.vl setlocal filetype=verilog
	au BufNewFile,BufRead *.bxrc setlocal filetype=bxrc
	au BufNewFile,BufRead *.odin setlocal filetype=odin
	au BufNewFile,BufRead *.comp setlocal filetype=comp
	au BufNewFIle,BufRead *.gpt setlocal filetype=gpt
	" au BufNewFile,BufRead *.md setlocal filetype=markdown
	au BufNewFile,BufRead *.lua.rename setlocal filetype=lua
	au BufNewFile,BufRead *.fmt setlocal filetype=protogen
augroup END


"----------------------------------------------------------------------
" language setup (on FileType autocmd)
"----------------------------------------------------------------------
function! s:language_setup()
	" echom "FileType: " . &ft
	if &ft == 'qf'
		setlocal nonumber
	endif
	let tags = expand("~/.vim/tags/") . &ft . '.tags'
	let dict = expand("~/.vim/dict/") . &ft . '.dict'
	if filereadable(tags)
		exec "setlocal tags+=" . fnameescape(tags)
	endif
	if filereadable(dict)
		exec "setlocal dict+=" . fnameescape(dict)
	endif
endfunc


" Persistent folding information
function! s:fold_restore(enable)
	if a:enable == 'true' || a:enable == 'yes' || a:enable != 0
		augroup VimUnixFoldGroup
			au! 
			au BufWrite,VimLeave * silent! mkview
			au BufRead * silent! loadview
		augroup END
	else
		augroup VimUnixFoldGroup
			au!
		augroup END
	endif
endfunc

command! -nargs=1 PersistFoldEnable call s:fold_restore(<q-args>)


" turn off number and signcolumn for terminal
if has('terminal') && exists(':terminal') == 2
	if exists('##TerminalOpen')
		augroup VimUnixTerminalGroup
			au! 
			" au TerminalOpen * setlocal nonumber signcolumn=no
		augroup END
	endif
endif


