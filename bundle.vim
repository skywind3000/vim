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


let g:bundle#uname = s:uname
let g:bundle#windows = (s:uname == 'windows')? 1 : 0


"----------------------------------------------------------------------
" include script
"----------------------------------------------------------------------
let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h')

if !exists(':IncScript')
	command! IncScript -nargs=1 exec 'so ' . fnameescape(s:home .'/<args>')
endif

function! bundle#path(path)
	let path = expand(s:home . '/' . a:path )
	return substitute(path, '\\', '/', 'g')
endfunc

function! s:path(path)
	return bundle#path(a:path)
endfunc


"----------------------------------------------------------------------
" packages begin
"----------------------------------------------------------------------
if !exists('g:bundle_group')
	let g:bundle_group = []
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
	Plug 'tpope/vim-fugitive'
	Plug 'tpope/vim-unimpaired'
	Plug 'godlygeek/tabular', { 'on': 'Tabularize' }
	Plug 'bootleq/vim-cycle'
	Plug 'tpope/vim-surround'

	nnoremap gb= :Tabularize /=<CR>
	vnoremap gb= :Tabularize /=<CR>
	nnoremap gb/ :Tabularize /\/\//l4c1<CR>
	vnoremap gb/ :Tabularize /\/\//l4c1<CR>
	nnoremap gb, :Tabularize /,/r0l1<CR>
	vnoremap gb, :Tabularize /,/r0l1<CR>
	nnoremap gbl :Tabularize /\|<cr>
	vnoremap gbl :Tabularize /\|<cr>
	nnoremap gbc :Tabularize /#/l4c1<cr>
	nnoremap gb<bar> :Tabularize /\|<cr>
	vnoremap gb<bar> :Tabularize /\|<cr>
	nnoremap gbr :Tabularize /\|/r0<cr>
	vnoremap gbr :Tabularize /\|/r0<cr>
	map gz <Plug>Sneak_s
	map gZ <Plug>Sneak_S

	IncScript site/bundle/cycle.vim
	IncScript site/bundle/easymotion.vim
endif


"----------------------------------------------------------------------
" package group - basic
"----------------------------------------------------------------------
if index(g:bundle_group, 'basic') >= 0
	Plug 'tpope/vim-rhubarb'
	Plug 'mhinz/vim-startify'
	Plug 'flazz/vim-colorschemes'
	Plug 'xolox/vim-misc'
	Plug 'terryma/vim-expand-region'
	Plug 'pprovost/vim-ps1', { 'for': 'ps1' }
	Plug 'tbastos/vim-lua', { 'for': 'lua' }
	Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['c', 'cpp'] }
	" Plug 'justinmk/vim-syntax-extra', { 'for': ['c', 'bison', 'flex', 'cpp'] }
	Plug 'vim-python/python-syntax', { 'for': ['python'] }
	Plug 'pboettch/vim-cmake-syntax', { 'for': ['cmake'] }
	Plug 'beyondmarc/hlsl.vim'
	Plug 'tpope/vim-eunuch'
	Plug 'dag/vim-fish'
	Plug 'skywind3000/vim-dict'
	
	if has('python3') || has('python')
		Plug 'Yggdroot/LeaderF'
		Plug 'tamago324/LeaderF-filer'
		IncScript site/bundle/leaderf.vim
	else
		Plug 'ctrlpvim/ctrlp.vim'
		Plug 'tacahiroy/ctrlp-funky'
		let g:ctrlp_map = ''
		noremap <c-p> :cclose<cr>:CtrlP<cr>
		noremap <c-n> :cclose<cr>:CtrlPMRUFiles<cr>
		noremap <m-p> :cclose<cr>:CtrlPFunky<cr>
		noremap <m-n> :cclose<cr>:CtrlPBuffer<cr>
	endif

	" noremap <space>ht :Startify<cr>
	" noremap <space>hy :tabnew<cr>:Startify<cr> 

	" let g:cpp_class_scope_highlight = 1
	let g:cpp_member_variable_highlight = 1
	let g:cpp_class_decl_highlight = 1
	" let g:cpp_experimental_simple_template_highlight = 1
	let g:cpp_concepts_highlight = 1
	let g:cpp_no_function_highlight = 1
	let g:cpp_posix_standard = 1

	let g:python_highlight_builtins = 1
	let g:python_highlight_builtin_objs = 1
	let g:python_highlight_builtin_types = 1
	let g:python_highlight_builtin_funcs = 1

	map <m-+> <Plug>(expand_region_expand)
	map <m-_> <Plug>(expand_region_shrink)
end


"----------------------------------------------------------------------
" package group - inter
"----------------------------------------------------------------------
if index(g:bundle_group, 'inter') >= 0
	Plug 'vim-scripts/L9'
	" Plug 'wsdjeg/FlyGrep.vim'
	" Plug 'tpope/vim-abolish'
	Plug 'honza/vim-snippets'
	" Plug 'vim-scripts/FuzzyFinder'
	" Plug 'rust-lang/rust.vim', { 'for': 'rust' }
	Plug 'xolox/vim-notes', { 'on': ['Note', 'SearchNotes', 'DeleteNotes', 'RecentNotes'] }
	Plug 'skywind3000/vimoutliner', { 'for': 'votl' }
	Plug 'mattn/webapi-vim'
	Plug 'mattn/gist-vim'
	Plug 'lambdalisue/vim-gista', { 'on': 'Gista' }
	if 1
		Plug 'inkarkat/vim-ingo-library'
		Plug 'inkarkat/vim-mark'
	else
		Plug 'lifepillar/vim-cheat40',
	endif
	" Plug 'Yggdroot/indentLine'

	if get(g:, 'asc_usnip', 0) == 0 || (has('python3') == 0 && has('python') == 0)
		Plug 'MarcWeber/vim-addon-mw-utils'
		Plug 'tomtom/tlib_vim'
		Plug 'garbas/vim-snipmate'
		IncScript site/bundle/snipmate.vim
	else
		Plug 'SirVer/ultisnips'
		IncScript site/bundle/ultisnips.vim
	endif

	if !isdirectory(expand('~/.vim/notes'))
		silent! call mkdir(expand('~/.vim/notes'), 'p')
	endif

endif


"----------------------------------------------------------------------
" package group - high
"----------------------------------------------------------------------
if index(g:bundle_group, 'high') >= 0
	Plug 'kshenoy/vim-signature'
	Plug 'mhinz/vim-signify'
	" Plug 'mh21/errormarker.vim'
	Plug 't9md/vim-choosewin'
	Plug 'francoiscabrol/ranger.vim'
	Plug 'kana/vim-textobj-user'
	" Plug 'kana/vim-textobj-indent'
	Plug 'kana/vim-textobj-syntax'
	Plug 'kana/vim-textobj-function', { 'for':['c', 'cpp', 'vim', 'java'] }
	Plug 'sgur/vim-textobj-parameter'
	Plug 'bps/vim-textobj-python', {'for': 'python'}
	Plug 'jceb/vim-textobj-uri'
	Plug 'tommcdo/vim-exchange'
	" Plug 'tpope/vim-apathy'

	let g:errormarker_disablemappings = 1
	nnoremap <silent> <leader>cm :ErrorAtCursor<CR>
	nnoremap <silent> <leader>cM :RemoveErrorMarkers<cr>

	nmap <m-e> <Plug>(choosewin)
	let g:ranger_map_keys = 0

end


"----------------------------------------------------------------------
" package group - opt
"----------------------------------------------------------------------
if index(g:bundle_group, 'opt') >= 0
	Plug 'junegunn/fzf'
	Plug 'junegunn/fzf.vim'
	Plug 'mhartington/oceanic-next'
	Plug 'jceb/vim-orgmode', { 'for': 'org' }
	Plug 'soft-aesthetic/soft-era-vim'
	Plug 'dyng/ctrlsf.vim'
	Plug 'itchyny/calendar.vim', { 'on': 'Calendar' }
	Plug 'tpope/vim-speeddating'
	Plug 'chiel92/vim-autoformat'
	Plug 'voldikss/vim-translator'
	Plug 'benmills/vimux'
	" Plug 'itchyny/vim-cursorword'
	let g:gutentags_modules = []
	if executable('ctags')
		let g:gutentags_modules += ['ctags']
	endif
	if executable('gtags-cscope') && executable('gtags')
		let g:gutentags_modules += ['gtags_cscope']
	endif
	if len(g:gutentags_modules) > 0
		" Plug 'ludovicchabant/vim-gutentags'
		Plug 'skywind3000/vim-gutentags'
	endif


	if s:uname == 'windows' 
		let g:python3_host_prog="python"
	endif
	if 1
		" Echo translation in the cmdline
		nmap <silent> <Leader>tt <Plug>Translate
		vmap <silent> <Leader>tt <Plug>TranslateV
		" Display translation in a window
		nmap <silent> <Leader>tw <Plug>TranslateW
		vmap <silent> <Leader>tw <Plug>TranslateWV
		" Replace the text with translation
		nmap <silent> <Leader>tr <Plug>TranslateR
		vmap <silent> <Leader>tr <Plug>TranslateRV
		let g:translator_window_enable_icon = v:true
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
	IncScript site/bundle/deoplete.vim
endif

" vimwiki
if index(g:bundle_group, 'vimwiki') >= 0
	Plug 'vimwiki/vimwiki'
	IncScript site/bundle/vimwiki.vim
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
	IncScript site/bundle/airline.vim
endif

" lightline
if index(g:bundle_group, 'lightline') >= 0
	Plug 'itchyny/lightline.vim'
	IncScript site/bundle/lightline.vim
endif

if index(g:bundle_group, 'coc') >= 0
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	IncScript site/bundle/coc.vim
endif

if index(g:bundle_group, 'vim-doge') >= 0
	Plug 'kkoomen/vim-doge'
	IncScript site/bundle/doge.vim
endif

if index(g:bundle_group, 'nerdtree') >= 0
	Plug 'scrooloose/nerdtree', {'on': ['NERDTree', 'NERDTreeFocus', 'NERDTreeToggle', 'NERDTreeCWD', 'NERDTreeFind'] }
	Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
	IncScript site/bundle/nerdtree.vim
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
	IncScript site/bundle/ale.vim
endif

if index(g:bundle_group, 'neomake') >= 0
	Plug 'neomake/neomake'
endif

if index(g:bundle_group, 'vista') >= 0
	Plug 'liuchengxu/vista.vim'
endif

if index(g:bundle_group, 'clap') >= 0
	Plug 'liuchengxu/vim-clap'
	IncScript site/bundle/clap.vim
endif

if index(g:bundle_group, 'neoformat') >= 0
	Plug 'sbdchd/neoformat'
    let g:neoformat_python_autopep8 = {
            \ 'exe': 'autopep8',
            \ 'args': ['-s 4', '-E'],
            \ 'replace': 1, 
            \ 'stdin': 0, 
            \ 'valid_exit_codes': [0, 23],
            \ 'no_append': 1,
            \ }

    let g:neoformat_enabled_python = ['autopep8']
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

if index(g:bundle_group, 'omni') >= 0
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
	IncScript site/bundle/lcn.vim
endif

if index(g:bundle_group, 'keysound') >= 0
	Plug 'skywind3000/vim-keysound'
	let g:keysound_theme = 'default'
	let g:keysound_enable = 1
endif

if index(g:bundle_group, 'icons') >= 0
	Plug 'istepura/vim-toolbar-icons-silk'
endif

if index(g:bundle_group, 'floaterm') >= 0
	Plug 'voldikss/vim-floaterm'
	IncScript site/bundle/floaterm.vim
endif

if index(g:bundle_group, 'tabnine') >= 0
	Plug 'codota/tabnine-vim'
	IncScript site/bundle/tabnine.vim
endif

if index(g:bundle_group, 'colors') >= 0
	Plug 'sonph/onehalf', {'rtp': 'vim/'}
endif

if index(g:bundle_group, 'which_key') >= 0
	Plug 'liuchengxu/vim-which-key'
	IncScript site/bundle/which_key.vim
endif

if index(g:bundle_group, 'supertab') >= 0
	Plug 'ervandew/supertab'
	IncScript site/bundle/supertab.vim
endif


"----------------------------------------------------------------------
" packages end
"----------------------------------------------------------------------
if exists('g:bundle_post')
	if type(g:bundle_post) == v:t_string
		exec g:bundle_post
	elseif type(g:bundle_post) == v:t_list
		exec join(g:bundle_post, "\n")
	endif
endif

call plug#end()



