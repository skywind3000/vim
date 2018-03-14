"----------------------------------------------------------------------
" check vundle existance
"----------------------------------------------------------------------
if !filereadable(expand('~/.vim/bundle/Vundle.vim/autoload/vundle.vim'))
	echom "cannot find vundle in ~/.vim/bundle/Vundle.vim"
	finish
endif


"----------------------------------------------------------------------
" bundle group
"----------------------------------------------------------------------
if !exists('g:bundle_group')
	let g:bundle_group = []
endif

let s:bundle_all = 0

if index(g:bundle_group, 'all') >= 0 
	let s:bundle_all = 1
endif


"----------------------------------------------------------------------
" check os
"----------------------------------------------------------------------
if has('win32') || has('win64') || has('win95') || has('win16')
	let s:uname = 'windows'
	let g:bundle_group += ['windows']
elseif has('win32unix')
	let s:uname = 'cygwin'
elseif has('unix')
	let s:uname = system("echo -n \"$(uname)\"")
	if !v:shell_error && s:uname == "Linux"
		let s:uname = 'linux'
		let g:bundle_group += ['linux']
	else
		let s:uname = 'darwin'
		let g:bundle_group += ['darwin']
	endif
else
	let s:uname = 'posix'
	let g:bundle_group += ['posix']
endif



"----------------------------------------------------------------------
" Bundle Header
"----------------------------------------------------------------------
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'


"----------------------------------------------------------------------
" Plugins
"----------------------------------------------------------------------


"----------------------------------------------------------------------
" Group - simple
"----------------------------------------------------------------------
if index(g:bundle_group, 'simple') >= 0 || s:bundle_all
	Plugin 'easymotion/vim-easymotion'
	Plugin 'Raimondi/delimitMate'
	Plugin 'godlygeek/tabular'
	Plugin 'justinmk/vim-dirvish'
	Plugin 'justinmk/vim-sneak'
	Plugin 'tpope/vim-unimpaired'
	Plugin 'pprovost/vim-ps1'

	nnoremap <space>a= :Tabularize /=<CR>
	vnoremap <space>a= :Tabularize /=<CR>
	nnoremap <space>a/ :Tabularize /\/\//l2c1l0<CR>
	vnoremap <space>a/ :Tabularize /\/\//l2c1l0<CR>
	nnoremap <space>a, :Tabularize /,/l0r1<CR>
	vnoremap <space>a, :Tabularize /,/l0r1<CR>
	nnoremap <space>al :Tabularize /\|<cr>
	vnoremap <space>al :Tabularize /\|<cr>
	nnoremap <space>a<bar> :Tabularize /\|<cr>
	vnoremap <space>a<bar> :Tabularize /\|<cr>
	nnoremap <space>ar :Tabularize /\|/r0<cr>
	vnoremap <space>ar :Tabularize /\|/r0<cr>
	map gz <Plug>Sneak_s
	map gZ <Plug>Sneak_S
endif


"----------------------------------------------------------------------
" Group - basic
"----------------------------------------------------------------------
if index(g:bundle_group, 'basic') >= 0 || s:bundle_all
	Plugin 'tpope/vim-fugitive'
	Plugin 'lambdalisue/vim-gista'
	Plugin 'mhinz/vim-startify'
	Plugin 'flazz/vim-colorschemes'
	Plugin 'xolox/vim-misc'
	Plugin 'octol/vim-cpp-enhanced-highlight'
	" Plugin 'vim-scripts/Colour-Sampler-Pack'

	if has('python') || has('python3')
		Plugin 'Yggdroot/LeaderF'
		let g:Lf_ShortcutF = '<c-p>'
		noremap <c-n> :LeaderfMru<cr>
		noremap <m-p> :LeaderfFunction<cr>
		noremap <m-n> :LeaderfBuffer<cr>
		noremap <m-m> :LeaderfTag<cr>
		let g:Lf_MruMaxFiles = 2048
		let g:Lf_MruFileExclude = ['*.so', '*.tmp']
		" let g:Lf_StlSeparator = { 'left': '♰', 'right': '♱', 'font': '' }
		let g:Lf_StlSeparator = { 'left': '', 'right': '', 'font': '' }
		let g:Lf_CommandMap = {'<C-C>': ['<Esc>', '<C-C>'], '<Esc>':[ '<C-q>' ]}
	else
		Plugin 'ctrlpvim/ctrlp.vim'
		Plugin 'tacahiroy/ctrlp-funky'
		let g:ctrlp_map = ''
		noremap <c-p> :CtrlP<cr>
		noremap <c-n> :CtrlPMRUFiles<cr>
		noremap <m-p> :CtrlPFunky<cr>
		noremap <m-n> :CtrlPBuffer<cr>
	endif

	let g:zv_file_types = {
				\ "^c$" : 'cpp,c',
				\ "^cpp$" : 'cpp,c',
				\ "python": 'python',
				\ "vim": 'vim'
				\ }

	noremap <space>ht :Startify<cr>
	noremap <space>hy :tabnew<cr>:Startify<cr> 

	let g:cpp_class_scope_highlight = 1
	let g:cpp_member_variable_highlight = 1
	let g:cpp_class_decl_highlight = 1
	let g:cpp_experimental_simple_template_highlight = 1
	let g:cpp_concepts_highlight = 1
	let g:cpp_no_function_highlight = 1
endif


"----------------------------------------------------------------------
" Group - inter
"----------------------------------------------------------------------
if index(g:bundle_group, 'inter') >= 0 || s:bundle_all
	Plugin 'rust-lang/rust.vim'
	Plugin 'skywind3000/vimoutliner'
	Plugin 'vim-scripts/FuzzyFinder'
	Plugin 'vim-scripts/L9'
	Plugin 'wsdjeg/FlyGrep.vim'
	Plugin 'tpope/vim-abolish'
	Plugin 'xolox/vim-notes'
	" Plugin 'mhartington/oceanic-next'
	" Plugin 'vim-scripts/CRefVim'
	" Plugin 'vim-scripts/DrawIt'
				
	if has('python')
		Plugin 'skywind3000/vimpress'
		Plugin 'honza/vim-snippets'
		" Plugin 'SirVer/ultisnips'
		Plugin 'garbas/vim-snipmate'
		Plugin 'MarcWeber/vim-addon-mw-utils'
		Plugin 'tomtom/tlib_vim'
	endif

	if !isdirectory(expand('~/.vim/notes'))
		silent! call mkdir(expand('~/.vim/notes'), 'p')
	endif

	noremap <space>bp :BlogPreview local<cr>
	noremap <space>bb :BlogPreview publish<cr>
	noremap <space>bs :BlogSave<cr>
	noremap <space>bd :BlogSave draft<cr>
	noremap <space>bn :BlogNew post<cr>
	noremap <space>bl :BlogList<cr>

	noremap <silent><tab>- :FufMruFile<cr>
	noremap <silent><tab>= :FufFile<cr>
	noremap <silent><tab>[ :FufBuffer<cr>
	noremap <silent><tab>] :FufBufferTag<cr>

	map <silent> <leader>ck <Plug>CRV_CRefVimAsk
	map <silent> <leader>cj <Plug>CRV_CRefVimInvoke

	vmap <silent> <leader>sr <Plug>StlRefVimVisual
	map <silent> <leader>sr <Plug>StlRefVimNormal
	map <silent> <leader>sw <Plug>StlRefVimAsk
	map <silent> <leader>sc <Plug>StlRefVimInvoke
	map <silent> <leader>se <Plug>StlRefVimExample

	if 1
		imap <expr> <m-e> pumvisible() ? '<esc>a<Plug>snipMateTrigger' : '<Plug>snipMateTrigger'
		imap <expr> <m-n> pumvisible() ? '<esc>a<Plug>snipMateNextOrTrigger' : '<Plug>snipMateNextOrTrigger'
		smap <m-j> <Plug>snipMateNextOrTrigger
		imap <expr> <m-p> pumvisible() ? '<esc>a<Plug>snipMateBack' : '<Plug>snipMateBack'
		smap <m-k> <Plug>snipMateBack
		imap <expr> <m-m> pumvisible() ? '<esc>a<Plug>snipMateShow' : '<Plug>snipMateShow'
	endif

endif


"----------------------------------------------------------------------
" Group - special
"----------------------------------------------------------------------
if index(g:bundle_group, 'high') >= 0
	Plugin 'kshenoy/vim-signature'
	Plugin 'mh21/errormarker.vim'
	" Plugin 'dracula/vim'
	Plugin 'mhinz/vim-signify'
	" Plugin 'Yggdroot/indentLine'

	let g:syntastic_always_populate_loc_list = 1
	let g:syntastic_auto_loc_list = 0
	let g:syntastic_check_on_open = 0
	let g:syntastic_check_on_wq = 0

	let g:errormarker_disablemappings = 1
	nnoremap <silent> <leader>cm :ErrorAtCursor<CR>
	nnoremap <silent> [e :ErrorAtCursor<CR>
	nnoremap <silent> <leader>cM :RemoveErrorMarkers<cr>

	"let &errorformat="%f:%l:%c: %t%*[^:]:%m,%f:%l: %t%*[^:]:%m," . &errorformat
	let g:indentLine_color_term = 239
	let g:indentLine_color_gui = '#A4E57E'
	let g:indentLine_color_tty_light = 7 " (default: 4)
	let g:indentLine_color_dark = 1 " (default: 2)
	let g:indentLine_bgcolor_term = 202
	let g:indentLine_bgcolor_gui = '#FF5F00'
	let g:indentLine_char = '|'
	let g:indentLine_enabled = 1
endif



"----------------------------------------------------------------------
" group opt 
"----------------------------------------------------------------------
if index(g:bundle_group, 'opt') >= 0
	" Plugin 'thinca/vim-quickrun'
	Plugin 'junegunn/fzf'
	" Plugin 'mattn/vim-terminal'
	" Plugin 'Shougo/vimshell.vim'
	" Plugin 'Shougo/vimproc.vim'
	" Plugin 'w0rp/ale'
	" Plugin 'airblade/vim-gitguttr'
	" let g:gitgutter_enabled = 1
	" let g:gitgutter_sign_column_always = 1
endif




"----------------------------------------------------------------------
" Group - windows
"----------------------------------------------------------------------
if index(g:bundle_group, 'windows') >= 0
endif


"----------------------------------------------------------------------
" Group - linux
"----------------------------------------------------------------------
if index(g:bundle_group, 'linux') >= 0
endif


"----------------------------------------------------------------------
" Group - posix
"----------------------------------------------------------------------
if index(g:bundle_group, 'posix') >= 0
endif



"----------------------------------------------------------------------
" Other plugins
"----------------------------------------------------------------------
if index(g:bundle_group, 'wakatime') >= 0
	if has('python')
		Plugin 'skywind3000/wakatime'
		" Plugin 'wakatime/vim-wakatime'
	endif
endif

if index(g:bundle_group, 'vimuiex') >= 0
	if !has('gui_running')
		Plugin 'skywind3000/vimuiex'
	endif
endif

if index(g:bundle_group, 'echodoc') >= 0
	Plugin 'Shougo/echodoc.vim'
	set noshowmode
	set shortmess+=c
	let g:echodoc#enable_at_startup = 1
endif

if index(g:bundle_group, 'deoplete') >= 0
	if has('nvim')
		Plugin 'Shougo/deoplete.nvim'
	else
		Plugin 'Shougo/deoplete.nvim'
		Plugin 'roxma/nvim-yarp'
		Plugin 'roxma/vim-hug-neovim-rpc'
	endif
	Plugin 'zchee/deoplete-clang'
	let g:deoplete#enable_at_startup = 1
	let g:deoplete#sources = {}
	let g:deoplete#sources._ = ['buffer', 'dictionary']
	let g:deoplete#sources.cpp = ['buffer', 'dictionary', 'libclang']
	function! s:setup_deoplete()
		call deoplete#initialize()
		call deoplete#enable()
	endfunc
	augroup Deoplete
		au!
		au VimEnter * call s:setup_deoplete()
	augroup END
	let g:deoplete#sources#clang#libclang_path = '/usr/lib/llvm-3.8/lib/libclang.so.1'
	let g:deoplete#sources#clang#clang_header = '/usr/include'
endif

if index(g:bundle_group, 'airline') >= 0
	Plugin 'bling/vim-airline'
	Plugin 'vim-airline/vim-airline-themes'
	let g:airline_left_sep = '♰'
	let g:airline_right_sep = '♱'
	let g:airline_exclude_preview = 1
	let g:airline_powerline_fonts = 1
	" let g:airline_theme='bubblegum'
endif

if index(g:bundle_group, 'completor') >= 0
	Plugin 'maralla/completor.vim'
endif

if index(g:bundle_group, 'neocomplete') >= 0
	if has('lua')
		Plugin 'Shougo/neocomplete.vim'
	endif
	set completeopt=longest,menuone
	"inoremap <expr> <TAB> pumvisible() ? "\<C-n>" : "\<tab>"
	"au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
	let g:neocomplete#enable_at_startup = 1 
endif


if index(g:bundle_group, 'nerdtree') >= 0
	Plugin 'scrooloose/nerdtree'
	Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
	let g:NERDTreeMinimalUI = 1
	let g:NERDTreeDirArrows = 1
	" let g:NERDTreeFileExtensionHighlightFullName = 1
	" let g:NERDTreeExactMatchHighlightFullName = 1
	" let g:NERDTreePatternMatchHighlightFullName = 1
endif


if index(g:bundle_group, 'grammer') >= 0
	Plugin 'rhysd/vim-grammarous'
	noremap <space>rg :GrammarousCheck --lang=en-US --no-move-to-first-error --no-preview<cr>
	map <space>rr <Plug>(grammarous-open-info-window)
	map <space>rv <Plug>(grammarous-move-to-info-window)
	map <space>rs <Plug>(grammarous-reset)
	map <space>rx <Plug>(grammarous-close-info-window)
	map <space>rm <Plug>(grammarous-remove-error)
	map <space>rd <Plug>(grammarous-disable-rule)
	map <space>rn <Plug>(grammarous-move-to-next-error)
	map <space>rp <Plug>(grammarous-move-to-previous-error)
endif


"----------------------------------------------------------------------
" Bundle Footer
"----------------------------------------------------------------------
call vundle#end()
filetype on


"----------------------------------------------------------------------
" Settings
"----------------------------------------------------------------------
let g:pydoc_cmd = 'python -m pydoc'
let g:gist_use_password_in_gitconfig = 1

if !exists('g:startify_disable_at_vimenter')
	let g:startify_disable_at_vimenter = 1
endif

let g:startify_session_dir = '~/.vim/session'


"----------------------------------------------------------------------
" keymaps
"----------------------------------------------------------------------



