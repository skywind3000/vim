"----------------------------------------------------------------------
" system detection 
"----------------------------------------------------------------------
if has('win32') || has('win64') || has('win95') || has('win16')
	let s:uname = 'windows'
elseif has('win32unix')
	let s:uname = 'cygwin'
elseif has('unix')
	let s:uname = system("echo -n \"$(uname)\"")
	if !v:shell_error && s:uname == "Linux"
		let s:uname = 'linux'
	else
		let s:uname = 'darwin'
	endif
else
	let s:uname = 'posix'
endif


"----------------------------------------------------------------------
" packages begin
"----------------------------------------------------------------------
if !exists('g:bundle_group')
	let g:bundle_group = []
endif

if !exists('g:bundle_post')
	let g:bundle_post = ''
endif

call plug#begin('~/.vim/bundles')


"----------------------------------------------------------------------
" package group - simple
"----------------------------------------------------------------------
if index(g:bundle_group, 'simple') >= 0
	Plug 'easymotion/vim-easymotion'
	Plug 'Raimondi/delimitMate'
	Plug 'justinmk/vim-dirvish'
	Plug 'justinmk/vim-sneak'
	Plug 'tpope/vim-unimpaired'
	Plug 'godlygeek/tabular', { 'on': 'Tabularize' }

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
" package group - basic
"----------------------------------------------------------------------
if index(g:bundle_group, 'basic') >= 0
	Plug 'tpope/vim-fugitive'
	Plug 'mhinz/vim-startify'
	Plug 'flazz/vim-colorschemes'
	Plug 'xolox/vim-misc'
	Plug 'terryma/vim-expand-region'
	Plug 'lambdalisue/vim-gista', { 'on': 'Gista' }
	Plug 'pprovost/vim-ps1', { 'for': 'ps1' }
	Plug 'tbastos/vim-lua', { 'for': 'lua' }
	Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['c', 'cpp'] }
	
	if has('python') || has('python3')
		Plug 'Yggdroot/LeaderF'
		let g:Lf_ShortcutF = '<c-p>'
		let g:Lf_ShortcutB = '<m-n>'
		noremap <c-n> :LeaderfMru<cr>
		noremap <m-p> :LeaderfFunction<cr>
		noremap <m-n> :LeaderfBuffer<cr>
		noremap <m-m> :LeaderfTag<cr>
		let g:Lf_MruMaxFiles = 2048
		let g:Lf_StlSeparator = { 'left': '', 'right': '', 'font': '' }
	else
		Plug 'ctrlpvim/ctrlp.vim'
		Plug 'tacahiroy/ctrlp-funky'
		let g:ctrlp_map = ''
		noremap <c-p> :CtrlP<cr>
		noremap <c-n> :CtrlPMRUFiles<cr>
		noremap <m-p> :CtrlPFunky<cr>
		noremap <m-n> :CtrlPBuffer<cr>
	endif

	noremap <space>ht :Startify<cr>
	noremap <space>hy :tabnew<cr>:Startify<cr> 

	let g:cpp_class_scope_highlight = 1
	let g:cpp_member_variable_highlight = 1
	let g:cpp_class_decl_highlight = 1
	let g:cpp_experimental_simple_template_highlight = 1
	let g:cpp_concepts_highlight = 1
	let g:cpp_no_function_highlight = 1

	map <m-=> <Plug>(expand_region_expand)
	map <m--> <Plug>(expand_region_shrink)
end


"----------------------------------------------------------------------
" package group - inter
"----------------------------------------------------------------------
if index(g:bundle_group, 'inter') >= 0
	Plug 'vim-scripts/L9'
	Plug 'wsdjeg/FlyGrep.vim'
	Plug 'tpope/vim-abolish'
	Plug 'skywind3000/vimoutliner'
	Plug 'honza/vim-snippets'
	Plug 'garbas/vim-snipmate'
	Plug 'MarcWeber/vim-addon-mw-utils'
	Plug 'tomtom/tlib_vim'
	Plug 'vim-scripts/FuzzyFinder'
	Plug 'rust-lang/rust.vim', { 'for': 'rust' }
	Plug 'xolox/vim-notes', { 'on': ['Note', 'SearchNotes', 'DeleteNotes', 'RecentNotes'] }

	if has('python')
		Plug 'skywind3000/vimpress', { 'on': ['BlogPreview', 'BlogSave', 'BlogNew', 'BlogList'] }
		noremap <space>bp :BlogPreview local<cr>
		noremap <space>bb :BlogPreview publish<cr>
		noremap <space>bs :BlogSave<cr>
		noremap <space>bd :BlogSave draft<cr>
		noremap <space>bn :BlogNew post<cr>
		noremap <space>bl :BlogList<cr>
	endif

	if !isdirectory(expand('~/.vim/notes'))
		silent! call mkdir(expand('~/.vim/notes'), 'p')
	endif

	noremap <silent><tab>- :FufMruFile<cr>
	noremap <silent><tab>= :FufFile<cr>
	noremap <silent><tab>[ :FufBuffer<cr>
	noremap <silent><tab>] :FufBufferTag<cr>

	if 0
		imap <expr> <m-e> pumvisible() ? '<c-g>u<Plug>snipMateTrigger' : '<Plug>snipMateTrigger'
		imap <expr> <m-n> pumvisible() ? '<c-g>u<Plug>snipMateNextOrTrigger' : '<Plug>snipMateNextOrTrigger'
		smap <m-n> <Plug>snipMateNextOrTrigger
		imap <expr> <m-p> pumvisible() ? '<c-g>u<Plug>snipMateBack' : '<Plug>snipMateBack'
		smap <m-p> <Plug>snipMateBack
		imap <expr> <m-m> pumvisible() ? '<c-g>u<Plug>snipMateShow' : '<Plug>snipMateShow'
	endif
endif


"----------------------------------------------------------------------
" package group - high
"----------------------------------------------------------------------
if index(g:bundle_group, 'high') >= 0
	Plug 'kshenoy/vim-signature'
	Plug 'mhinz/vim-signify'
	Plug 'mh21/errormarker.vim'
	Plug 't9md/vim-choosewin'
	Plug 'francoiscabrol/ranger.vim'

	let g:errormarker_disablemappings = 1
	nnoremap <silent> <leader>cm :ErrorAtCursor<CR>
	nnoremap <silent> [e :ErrorAtCursor<CR>
	nnoremap <silent> <leader>cM :RemoveErrorMarkers<cr>

	nmap <m-e> <Plug>(choosewin)
	let g:ranger_map_keys = 0

end


"----------------------------------------------------------------------
" package group - opt
"----------------------------------------------------------------------
if index(g:bundle_group, 'opt') >= 0
	Plug 'junegunn/fzf'
	Plug 'mhartington/oceanic-next'
	Plug 'asins/vim-dict'
	Plug 'tpope/vim-speeddating'
	Plug 'itchyny/calendar.vim', { 'on': 'Calendar' }
	Plug 'jceb/vim-orgmode', { 'for': 'org' }
endif


"----------------------------------------------------------------------
" optional 
"----------------------------------------------------------------------

" deoplete
if index(g:bundle_group, 'deoplete') >= 0
	if has('nvim')
		Plug 'Shougo/deoplete.nvim'
	else
		Plug 'Shougo/deoplete.nvim'
		Plug 'roxma/nvim-yarp'
		Plug 'roxma/vim-hug-neovim-rpc'
	endif

	Plug 'zchee/deoplete-clang'
	Plug 'zchee/deoplete-jedi'

	let g:deoplete#enable_at_startup = 1
	let g:deoplete#enable_smart_case = 1
	let g:deoplete#enable_refresh_always = 1

	inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<tab>"
	inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
	inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
	inoremap <expr><BS> deoplete#smart_close_popup()."\<bs>"
	inoremap <expr> <cr> pumvisible() ? "\<C-y>\<cr>" : "\<cr>"

	let g:deoplete#sources = {}
	let g:deoplete#sources._ = ['buffer', 'dictionary']
	let g:deoplete#sources.cpp = ['clang']
	let g:deoplete#sources.python = ['jedi']

	set shortmess+=c
	let g:echodoc#enable_at_startup = 1

	if exists('g:python_host_prog')
		let g:deoplete#sources#jedi#python_path = g:python_host_prog
	endif

	let g:deoplete#sources#jedi#enable_cache = 1

endif

" echodoc
if index(g:bundle_group, 'echodoc') >= 0
	Plug 'Shougo/echodoc.vim'
	set noshowmode
	let g:echodoc#enable_at_startup = 1
endif

" airline
if index(g:bundle_group, 'airline') >= 0
	Plug 'bling/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	let g:airline_left_sep = ''
	let g:airline_left_alt_sep = ''
	let g:airline_right_sep = ''
	let g:airline_right_alt_sep = ''
	let g:airline_exclude_preview = 1
	let g:airline_powerline_fonts = 1
	" let g:airline_theme='bubblegum'
endif


if index(g:bundle_group, 'nerdtree') >= 0
	Plug 'scrooloose/nerdtree', {'on': ['NERDTree', 'NERDTreeFocus', 'NERDTreeToggle', 'NERDTreeCWD', 'NERDTreeFind'] }
	Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
	let g:NERDTreeMinimalUI = 1
	let g:NERDTreeDirArrows = 1
	let g:NERDTreeHijackNetrw = 0
	" let g:NERDTreeFileExtensionHighlightFullName = 1
	" let g:NERDTreeExactMatchHighlightFullName = 1
	" let g:NERDTreePatternMatchHighlightFullName = 1
	noremap <space>tn :NERDTree<cr>
	noremap <space>to :NERDTreeFocus<cr>
	noremap <space>tm :NERDTreeMirror<cr>
	noremap <space>tt :NERDTreeToggle<cr>
endif

if index(g:bundle_group, 'grammer') >= 0
	Plug 'rhysd/vim-grammarous'
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


if index(g:bundle_group, 'textobj') >= 0
	Plug 'kana/vim-textobj-user'
	" Plug 'kana/vim-textobj-indent'
	Plug 'kana/vim-textobj-syntax'
	Plug 'kana/vim-textobj-function', { 'for':['c', 'cpp', 'vim', 'java'] }
	Plug 'sgur/vim-textobj-parameter'
	Plug 'bps/vim-textobj-python', {'for': 'python'}
	Plug 'jceb/vim-textobj-uri'
	" Plug 'wellle/targets.vim'
endif



"----------------------------------------------------------------------
" packages end
"----------------------------------------------------------------------
if g:bundle_post != ''
	exec g:bundle_post
endif

call plug#end()



