" just another setup file yet, some handy stuff


"----------------------------------------------------------------------
" Better setup for VIM 7.0 and later
"----------------------------------------------------------------------
filetype plugin indent on
set hlsearch
set incsearch
set wildmenu
set ignorecase
set cpo-=<
set lazyredraw
set errorformat+=[%f:%l]\ ->\ %m,[%f:%l]:%m
set vop=folds,cursor
set fdm=indent
set foldlevel=99
set tags=./.tags;,.tags
set formatoptions+=m
set formatoptions+=B
set history=2000
set showcmd

noremap <tab>/ :emenu <C-Z>

let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')

" VimImport / VimLoad
command! -nargs=1 VimImport exec 'so '.s:home.'/'.'<args>'
command! -nargs=1 VimLoad exec 'set rtp+='.s:home.'/'.'<args>'

if has('patch-7.4.500') || v:version >= 800
	if !has('nvim')
		set cryptmethod=blowfish2
	endif
endif

" fixed cursor shaping compatible issues for some terminals
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

" DiffOrig command
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
          \ | wincmd p | diffthis
endif

" use ~/.vim/tmp as backup directory
call Backup_Directory()


"----------------------------------------------------------------------
" autocmd group
"----------------------------------------------------------------------
augroup AscUnixGroup
	au!
	au FileType * call s:language_setup()
	au User AsyncRunStart call asyncrun#quickfix_toggle(6, 1)
	au User VimScope,VimMakeStart call vimmake#toggle_quickfix(6, 1)
	au BufNewFile,BufRead *.as setlocal filetype=actionscript
	au BufNewFile,BufRead *.pro setlocal filetype=prolog
	au BufNewFile,BufRead *.es setlocal filetype=erlang
	au BufNewFile,BufRead *.asc setlocal filetype=asciidoc
	au BufNewFile,BufRead *.vl setlocal filetype=verilog
augroup END


"----------------------------------------------------------------------
" language setup (on FileType autocmd)
"----------------------------------------------------------------------
function! s:language_setup()
	if &ft == 'cpp' || &ft == 'c'
		setlocal commentstring=//\ %s
	elseif &ft == 'markdown'
		setlocal wrap
	elseif &ft == 'qf'
		setlocal nonumber
	endif
	let tags = expand("~/.vim/tags/") . &ft . '.tags'
	let dict = expand("~/.vim/dict/") . &ft . '.dict'
	exec "setlocal tags+=" . fnameescape(tags)
	exec "setlocal dict+=" . fnameescape(dict)
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
			au TerminalOpen * setlocal nonumber signcolumn=no
		augroup END
	endif
endif


" setup shell 
if &shell =~# 'fish'
	set shell=sh
endif


"----------------------------------------------------------------------
" highlighting tune
"----------------------------------------------------------------------
function! VimTuneHighlight(mode)
endfunc



