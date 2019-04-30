"----------------------------------------------------------------------
" system detection 
"----------------------------------------------------------------------
if exists('g:asc_uname')
	let s:uname = g:asc_uname
elseif has('win32') || has('win64') || has('win95') || has('win16')
	let s:uname = 'windows'
elseif has('win32unix')
	let s:uname = 'cygwin'
elseif has('unix')
	let s:uname = substitute(system("uname"), '\s*\n$', '', 'g')
	if !v:shell_error && s:uname == "Linux"
		let s:uname = 'linux'
	elseif v:shell_error == 0 && match(s:uname, 'Darwin') >= 0
		let s:uname = 'darwin'
	else
		let s:uname = 'posix'
	endif
else
	let s:uname = 'posix'
endif


let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h')

function! s:path(path)
	let path = expand(s:home . '/' . a:path )
	return substitute(path, '\\', '/', 'g')
endfunc


"----------------------------------------------------------------------
" packages begin
"----------------------------------------------------------------------
if !exists('g:bundle_group')
	let g:bundle_group = []
endif

if !exists('g:bundle_post')
	let g:bundle_post = ''
endif

call plug#begin(get(g:, 'bundle_home', '~/.vim/bundles'))


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
	Plug 'bootleq/vim-cycle'
	Plug 'tpope/vim-surround'

	nnoremap gb= :Tabularize /=<CR>
	vnoremap gb= :Tabularize /=<CR>
	nnoremap gb/ :Tabularize /\/\//l4c1<CR>
	vnoremap gb/ :Tabularize /\/\//l4c1<CR>
	nnoremap gb, :Tabularize /,/l0r1<CR>
	vnoremap gb, :Tabularize /,/l0r1<CR>
	nnoremap gbl :Tabularize /\|<cr>
	vnoremap gbl :Tabularize /\|<cr>
	nnoremap gbc :Tabularize /#/l4c1<cr>
	nnoremap gb<bar> :Tabularize /\|<cr>
	vnoremap gb<bar> :Tabularize /\|<cr>
	nnoremap gbr :Tabularize /\|/r0<cr>
	vnoremap gbr :Tabularize /\|/r0<cr>
	map gz <Plug>Sneak_s
	map gZ <Plug>Sneak_S

	noremap <silent> <Plug>CycleFallbackNext <C-A>
	noremap <silent> <Plug>CycleFallbackPrev <C-X>
	nmap <silent> <c-a> <Plug>CycleNext
	vmap <silent> <c-a> <Plug>CycleNext
	nmap <silent> <c-x> <Plug>CyclePrev
	vmap <silent> <c-x> <Plug>CyclePrev
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
	Plug 'justinmk/vim-syntax-extra', { 'for': ['c', 'bison', 'flex', 'cpp'] }
	Plug 'vim-python/python-syntax', { 'for': ['python'] }
	Plug 'tpope/vim-eunuch'
	Plug 'dag/vim-fish'
	
	if has('python') || has('python3')
		Plug 'Yggdroot/LeaderF'
		let g:Lf_ShortcutF = '<c-p>'
		let g:Lf_ShortcutB = '<m-n>'
		noremap <c-n> :cclose<cr>:Leaderf mru --regexMode<cr>
		noremap <m-p> :cclose<cr>:LeaderfFunction!<cr>
		noremap <m-P> :cclose<cr>:LeaderfBufTag!<cr>
		noremap <m-n> :cclose<cr>:LeaderfBuffer<cr>
		noremap <m-m> :cclose<cr>:LeaderfTag<cr>
		let g:Lf_MruMaxFiles = 2048
		let g:Lf_StlSeparator = { 'left': '', 'right': '', 'font': '' }
	else
		Plug 'ctrlpvim/ctrlp.vim'
		Plug 'tacahiroy/ctrlp-funky'
		let g:ctrlp_map = ''
		noremap <c-p> :cclose<cr>:CtrlP<cr>
		noremap <c-n> :cclose<cr>:CtrlPMRUFiles<cr>
		noremap <m-p> :cclose<cr>:CtrlPFunky<cr>
		noremap <m-n> :cclose<cr>:CtrlPBuffer<cr>
	endif

	noremap <space>ht :Startify<cr>
	noremap <space>hy :tabnew<cr>:Startify<cr> 

	let g:cpp_class_scope_highlight = 1
	let g:cpp_member_variable_highlight = 1
	let g:cpp_class_decl_highlight = 1
	" let g:cpp_experimental_simple_template_highlight = 1
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
	" Plug 'wsdjeg/FlyGrep.vim'
	Plug 'tpope/vim-abolish'
	Plug 'honza/vim-snippets'
	Plug 'MarcWeber/vim-addon-mw-utils'
	Plug 'tomtom/tlib_vim'
	Plug 'garbas/vim-snipmate'
	Plug 'vim-scripts/FuzzyFinder'
	Plug 'rust-lang/rust.vim', { 'for': 'rust' }
	Plug 'xolox/vim-notes', { 'on': ['Note', 'SearchNotes', 'DeleteNotes', 'RecentNotes'] }
	Plug 'skywind3000/vimoutliner', { 'for': 'votl' }
	" Plug 'Yggdroot/indentLine'

	if has('python')
		Plug 'skywind3000/vimpress', { 'on': ['BlogPreview', 'BlogSave', 'BlogNew', 'BlogList'] }
		noremap <space>bp :BlogPreview local<cr>
		noremap <space>bb :BlogPreview publish<cr>
		noremap <space>bs :BlogSave<cr>
		noremap <space>bd :BlogSave draft<cr>
		noremap <space>bn :BlogNew post<cr>
		noremap <space>bl :BlogList<cr>
	endif

	if has('python') || has('python3')
		" Plug 'SirVer/ultisnips'
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
	elseif 1
		imap <expr> <m-e> pumvisible() ? '<c-g>u<Plug>snipMateNextOrTrigger' : '<Plug>snipMateNextOrTrigger'
		smap <m-e> <Plug>snipMateNextOrTrigger
		imap <expr> <m-E> pumvisible() ? '<c-g>u<Plug>snipMateBack' : '<Plug>snipMateBack'
		smap <m-E> <Plug>snipMateBack
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
	Plug 'kana/vim-textobj-user'
	" Plug 'kana/vim-textobj-indent'
	Plug 'kana/vim-textobj-syntax'
	Plug 'kana/vim-textobj-function', { 'for':['c', 'cpp', 'vim', 'java'] }
	Plug 'sgur/vim-textobj-parameter'
	Plug 'bps/vim-textobj-python', {'for': 'python'}
	Plug 'jceb/vim-textobj-uri'

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
	Plug 'jceb/vim-orgmode', { 'for': 'org' }
	Plug 'soft-aesthetic/soft-era-vim'
	Plug 'dyng/ctrlsf.vim'
	Plug 'itchyny/calendar.vim', { 'on': 'Calendar' }
	Plug 'tpope/vim-speeddating'
	" Plug 'itchyny/vim-cursorword'
	let g:gutentags_modules = []
	if executable('ctags')
		let g:gutentags_modules += ['ctags']
	endif
	if executable('gtags-cscope') && executable('gtags')
		let g:gutentags_modules += ['gtags_cscope']
	endif
	if len(g:gutentags_modules) > 0
		if s:uname != 'windows'
			Plug 'ludovicchabant/vim-gutentags'
		else
			Plug 'ludovicchabant/vim-gutentags'
			" Plug 'skywind3000/vim-gutentags'
		endif
	endif
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

	" Plug 'zchee/deoplete-clang'
	Plug 'zchee/deoplete-jedi'

	let g:deoplete#enable_at_startup = 1
	let g:deoplete#enable_smart_case = 1
	let g:deoplete#enable_refresh_always = 1

	inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<tab>"
	inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
	inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
	inoremap <expr><BS> deoplete#smart_close_popup()."\<bs>"
	inoremap <expr> <cr> pumvisible() ? "\<C-y>\<cr>" : "\<cr>"

	if 0
		let g:deoplete#sources = {}
		let g:deoplete#sources._ = ['buffer', 'dictionary']
		" let g:deoplete#sources.cpp = ['clang']
		let g:deoplete#sources.python = ['jedi']
		let g:deoplete#sources.cpp = ['omni']
	endif

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
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	let g:airline_left_sep = ''
	let g:airline_left_alt_sep = ''
	let g:airline_right_sep = ''
	let g:airline_right_alt_sep = ''
	let g:airline_powerline_fonts = 0
	let g:airline_exclude_preview = 1
	let g:airline_section_b = '%n'
	" let g:airline_section_z = '%P %l/%L%{g:airline_symbols.maxlinenr} : %v'
	" let g:airline_section_z = '%{AirlineLineNumber()}'
	" let g:airline_theme='bubblegum'
endif

" lightline
if index(g:bundle_group, 'lightline') >= 0
	Plug 'itchyny/lightline.vim'
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


if index(g:bundle_group, 'ale') >= 0
	Plug 'w0rp/ale'

	let g:airline#extensions#ale#enabled = 1
	let g:ale_linters = {
				\ 'c': ['gcc', 'cppcheck'], 
				\ 'cpp': ['gcc', 'cppcheck'], 
				\ 'python': ['flake8', 'pylint'], 
				\ 'lua': ['luac'], 
				\ 'go': ['go build', 'gofmt'],
				\ 'java': ['javac'],
				\ 'javascript': ['eslint'], 
				\ }

	function! s:lintcfg(name)
		let conf = s:path('tools/conf/')
		let path1 = conf . a:name
		let path2 = expand('~/.vim/linter/'. a:name)
		return shellescape(filereadable(path2)? path2 : path1)
	endfunc

	let g:ale_python_flake8_options = '--conf='.s:lintcfg('flake8.conf')
	let g:ale_python_pylint_options = '--rcfile='.s:lintcfg('pylint.conf')
	let g:ale_python_pylint_options .= ' --disable=W'
	let g:ale_c_gcc_options = '-Wall -O2 -std=c99'
	let g:ale_cpp_gcc_options = '-Wall -O2 -std=c++14'
	let g:ale_c_cppcheck_options = ''
	let g:ale_cpp_cppcheck_options = ''
	let g:ale_lua_luacheck_options = '-d'

	" let g:ale_linters.text = ['textlint', 'write-good', 'languagetool']
	" let g:ale_linters.lua += ['luacheck']
	
	if executable('gcc') == 0 && executable('clang')
		let g:ale_linters.c += ['clang']
		let g:ale_linters.cpp += ['clang']
	endif
endif

if index(g:bundle_group, 'neomake') >= 0
	Plug 'neomake/neomake'
endif


if index(g:bundle_group, 'neocomplete') >= 0
	Plug 'Shougo/neocomplete.vim'
	let g:neocomplete#enable_at_startup = 1
	let g:neocomplete#sources#syntax#min_keyword_length = 2
	inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
	inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
	inoremap <expr><C-g><C-g> neocomplete#undo_completion()
	inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
	function! s:my_cr_function()
		return (pumvisible() ? "\<C-y>" : "" ) . "\<CR>"
	endfunction
endif

if index(g:bundle_group, 'omni')
	Plug 'vim-scripts/OmniCppComplete', {'for':['cpp']}
	" Plug 'c9s/perlomni.vim', {'for':['perl']}
	Plug 'shawncplus/phpcomplete.vim', {'for': ['php']}
	" Plug 'artur-shaik/vim-javacomplete2'
	Plug 'othree/html5.vim', {'for': ['html']}
	" Plug 'xolox/vim-lua-ftplugin', {'for': ['lua']}
	let g:lua_complete_omni = 0
	let g:lua_check_globals = 0
	let g:lua_check_syntax = 0
	let g:lua_define_completion_mappings = 0
	" autocmd FileType java setlocal omnifunc=javacomplete#Complete
endif


if index(g:bundle_group, 'lsp') >= 0
	Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next' }
	let g:LanguageClient_loadSettings = 1
	let g:LanguageClient_diagnosticsEnable = 0
	let g:LanguageClient_settingsPath = expand('~/.vim/languageclient.json')
	let g:LanguageClient_selectionUI = 'quickfix'
	let g:LanguageClient_diagnosticsList = v:null
	let g:LanguageClient_hoverPreview = 'Never'
	" let g:LanguageClient_loggingLevel = 'DEBUG'
	if !exists('g:LanguageClient_serverCommands')
		let g:LanguageClient_serverCommands = {}
		let g:LanguageClient_serverCommands.c = ['cquery']
		let g:LanguageClient_serverCommands.cpp = ['cquery']
	endif
	noremap <leader>rd :call LanguageClient#textDocument_definition({'gotoCmd':'FileSwitch tabe'})<cr>
	noremap <leader>re :call LanguageClient#textDocument_definition({'gotoCmd':'PreviewFile'})<cr>
	noremap <leader>rr :call LanguageClient#textDocument_references()<cr>
	noremap <leader>rv :call LanguageClient#textDocument_hover()<cr>
endif

if index(g:bundle_group, 'keysound') >= 0
	Plug 'skywind3000/vim-keysound'
	let g:keysound_theme = 'default'
	let g:keysound_enable = 1
endif


"----------------------------------------------------------------------
" packages end
"----------------------------------------------------------------------
if g:bundle_post != ''
	exec g:bundle_post
endif

call plug#end()



