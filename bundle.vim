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

let g:bundle_enabled = {}
for key in g:bundle_group | let g:bundle_enabled[key] = 1 | endfor
let s:enabled = g:bundle_enabled


call plug#begin(get(g:, 'bundle_home', '~/.vim/bundles'))


"----------------------------------------------------------------------
" package group - simple
"----------------------------------------------------------------------
if has_key(s:enabled, 'simple')
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
	nnoremap gb* :Tabularize /\/\*/l4c1<cr>
	vnoremap gb* :Tabularize /\/\*/l4c1<cr>
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
if has_key(s:enabled, 'basic')
	Plug 't9md/vim-choosewin'
	Plug 'tpope/vim-rhubarb'
	Plug 'mhinz/vim-startify'
	Plug 'flazz/vim-colorschemes'
	Plug 'xolox/vim-misc'
	Plug 'terryma/vim-expand-region'
	Plug 'skywind3000/vim-dict'
	Plug 'tommcdo/vim-exchange'
	Plug 'tommcdo/vim-lion'

	Plug 'pprovost/vim-ps1', { 'for': 'ps1' }
	Plug 'tbastos/vim-lua', { 'for': 'lua' }
	Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['c', 'cpp'] }
	Plug 'vim-python/python-syntax', { 'for': ['python'] }
	Plug 'pboettch/vim-cmake-syntax', { 'for': ['cmake'] }
	Plug 'beyondmarc/hlsl.vim'
	Plug 'tpope/vim-eunuch'
	Plug 'dag/vim-fish'

	Plug 'kana/vim-textobj-user'
	" Plug 'kana/vim-textobj-indent'
	Plug 'kana/vim-textobj-syntax'
	Plug 'kana/vim-textobj-function', { 'for':['c', 'cpp', 'vim', 'java'] }
	Plug 'sgur/vim-textobj-parameter'
	Plug 'bps/vim-textobj-python', {'for': 'python'}
	Plug 'jceb/vim-textobj-uri'


	" Plug 'justinmk/vim-syntax-extra', { 'for': ['c', 'bison', 'flex', 'cpp'] }
	
	if has('python3') || has('python')
		Plug 'Yggdroot/LeaderF'
		Plug 'tamago324/LeaderF-filer'
		Plug 'voldikss/LeaderF-emoji'
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

	nmap <m-e> <Plug>(choosewin)
	map <m-+> <Plug>(expand_region_expand)
	map <m-_> <Plug>(expand_region_shrink)
end


"----------------------------------------------------------------------
" package group - inter
"----------------------------------------------------------------------
if has_key(s:enabled, 'inter')
	Plug 'vim-scripts/L9'
	Plug 'honza/vim-snippets'
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
if has_key(s:enabled, 'high')
	Plug 'kshenoy/vim-signature'
	Plug 'mhinz/vim-signify'
	Plug 'junegunn/fzf'
	Plug 'junegunn/fzf.vim'
	Plug 'jceb/vim-orgmode', { 'for': 'org' }
	Plug 'itchyny/calendar.vim', { 'on': 'Calendar' }
	Plug 'francoiscabrol/ranger.vim'
	Plug 'sbdchd/neoformat'
	Plug 'dhruvasagar/vim-table-mode'

	if has('python3') || has('python2')
		Plug 'chiel92/vim-autoformat'
		IncScript site/bundle/autoformat.vim
	endif

	IncScript site/bundle/neoformat.vim

	let g:errormarker_disablemappings = 1
	nnoremap <silent> <leader>cm :ErrorAtCursor<CR>
	nnoremap <silent> <leader>cM :RemoveErrorMarkers<cr>

	let g:ranger_map_keys = 0

end


"----------------------------------------------------------------------
" package group - opt
"----------------------------------------------------------------------
if has_key(s:enabled, 'opt')
	Plug 'dyng/ctrlsf.vim'
	Plug 'tpope/vim-speeddating'
	Plug 'voldikss/vim-translator'
	Plug 'mhartington/oceanic-next'
	Plug 'soft-aesthetic/soft-era-vim'
	" Plug 'tpope/vim-apathy'
	" Plug 'mh21/errormarker.vim'

	if executable('tmux')
		Plug 'benmills/vimux'
	endif

	" Plug 'itchyny/vim-cursorword'
	let g:gutentags_modules = []
	if executable('ctags')
		let g:gutentags_modules += ['ctags']
	endif
	if executable('gtags-cscope') && executable('gtags')
		let g:gutentags_modules += ['gtags_cscope']
	endif
	if len(g:gutentags_modules) > 0
		Plug 'ludovicchabant/vim-gutentags'
		" Plug 'skywind3000/vim-gutentags'
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
if has_key(s:enabled, 'deoplete')
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
if has_key(s:enabled, 'vimwiki')
	Plug 'vimwiki/vimwiki'
	IncScript site/bundle/vimwiki.vim
endif

" echodoc
if has_key(s:enabled, 'echodoc')
	Plug 'Shougo/echodoc.vim'
	set noshowmode
	let g:echodoc#enable_at_startup = 1
endif

" airline
if has_key(s:enabled, 'airline')
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	IncScript site/bundle/airline.vim
endif

" lightline
if has_key(s:enabled, 'lightline')
	Plug 'itchyny/lightline.vim'
	IncScript site/bundle/lightline.vim
endif

if has_key(s:enabled, 'coc')
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	IncScript site/bundle/coc.vim
endif

if has_key(s:enabled, 'vim-doge')
	Plug 'kkoomen/vim-doge'
	IncScript site/bundle/doge.vim
endif

if has_key(s:enabled, 'nerdtree')
	Plug 'scrooloose/nerdtree', {'on': ['NERDTree', 'NERDTreeFocus', 'NERDTreeToggle', 'NERDTreeCWD', 'NERDTreeFind'] }
	Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
	IncScript site/bundle/nerdtree.vim
endif

if has_key(s:enabled, 'grammer')
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


if has_key(s:enabled, 'ale')
	Plug 'w0rp/ale'
	IncScript site/bundle/ale.vim
endif

if has_key(s:enabled, 'neomake')
	Plug 'neomake/neomake'
endif

if has_key(s:enabled, 'vista')
	Plug 'liuchengxu/vista.vim'
endif

if has_key(s:enabled, 'clap')
	Plug 'liuchengxu/vim-clap'
	IncScript site/bundle/clap.vim
endif

if has_key(s:enabled, 'splitjoin')
	Plug 'AndrewRadev/splitjoin.vim'
endif

if has_key(s:enabled, 'neocomplete')
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

if has_key(s:enabled, 'omni')
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


if has_key(s:enabled, 'lsp-lcn')
	Plug 'autozimu/LanguageClient-neovim', { 'branch': 'next' }
	IncScript site/bundle/lcn.vim
endif

if has_key(s:enabled, 'keysound')
	Plug 'skywind3000/vim-keysound'
	let g:keysound_theme = 'default'
	let g:keysound_enable = 1
endif

if has_key(s:enabled, 'icons')
	Plug 'istepura/vim-toolbar-icons-silk'
endif

if has_key(s:enabled, 'floaterm')
	Plug 'voldikss/vim-floaterm'
	IncScript site/bundle/floaterm.vim
endif

if has_key(s:enabled, 'tabnine')
	Plug 'codota/tabnine-vim'
	IncScript site/bundle/tabnine.vim
endif

if has_key(s:enabled, 'colors')
	Plug 'sonph/onehalf', {'rtp': 'vim/'}
	Plug 'sainnhe/sonokai'
	Plug 'chuling/ci_dark'
	Plug 'arcticicestudio/nord-vim'
	Plug 'romainl/Apprentice'
	Plug 'arzg/vim-colors-xcode'
endif

if has_key(s:enabled, 'which_key')
	Plug 'liuchengxu/vim-which-key'
	IncScript site/bundle/which_key.vim
endif

if has_key(s:enabled, 'supertab')
	Plug 'ervandew/supertab'
	IncScript site/bundle/supertab.vim
endif

if has_key(s:enabled, 'blamer')
	Plug 'APZelos/blamer.nvim'
endif

if has_key(s:enabled, 'cursorword')
	Plug 'itchyny/vim-cursorword'
	let g:cursorword_delay = 100
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


