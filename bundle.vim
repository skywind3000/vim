"----------------------------------------------------------------------
" system detection 
"----------------------------------------------------------------------
let s:uname = asclib#platform#uname()
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
	Plug 'justinmk/vim-dirvish'
	Plug 'justinmk/vim-sneak'
	Plug 'tpope/vim-fugitive'
	Plug 'tpope/vim-unimpaired'
	Plug 'godlygeek/tabular', { 'on': 'Tabularize' }
	Plug 'bootleq/vim-cycle'
	Plug 'tpope/vim-surround'

	if !has_key(s:enabled, 'autopair')
		Plug 'Raimondi/delimitMate'
	else
		Plug 'jiangmiao/auto-pairs'
	endif

	" Plug 'romainl/vim-cool'
	
	if has_key(s:enabled, 'stargate') && has('nvim') == 0 && v:version >= 900
		Plug 'monkoose/vim9-stargate'
		IncScript site/bundle/stargate.vim
	else
		Plug 'easymotion/vim-easymotion'
		IncScript site/bundle/easymotion.vim
	endif

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
	vnoremap gbc :Tabularize /#/l4c1<cr>
	nnoremap gb<bar> :Tabularize /\|<cr>
	vnoremap gb<bar> :Tabularize /\|<cr>
	nnoremap gbr :Tabularize /\|/r0<cr>
	vnoremap gbr :Tabularize /\|/r0<cr>

	nmap gz <Plug>Sneak_s
	nmap gZ <Plug>Sneak_S
	vmap gz <Plug>Sneak_s
	vmap gZ <Plug>Sneak_S
	xmap gz <Plug>Sneak_s
	xmap gZ <Plug>Sneak_S

	IncScript site/bundle/dirvish.vim
	IncScript site/bundle/cycle.vim
	IncScript site/bundle/git.vim
endif


"----------------------------------------------------------------------
" package group - basic
"----------------------------------------------------------------------
if has_key(s:enabled, 'basic')
	Plug 't9md/vim-choosewin'
	Plug 'tpope/vim-rhubarb'
	Plug 'mhinz/vim-startify'
	Plug 'xolox/vim-misc'
	Plug 'terryma/vim-expand-region'
	Plug 'skywind3000/vim-dict'
	Plug 'tommcdo/vim-exchange'
	Plug 'tommcdo/vim-lion'
	" Plug 'embear/vim-localvimrc'

	Plug 'pprovost/vim-ps1', { 'for': 'ps1' }
	Plug 'tbastos/vim-lua', { 'for': 'lua' }
	Plug 'vim-python/python-syntax', { 'for': ['python'] }
	Plug 'pboettch/vim-cmake-syntax', { 'for': ['cmake'] }
	Plug 'skywind3000/vim-flex-bison-syntax', { 'for': ['yacc', 'lex'] }
	Plug 'lark-parser/vim-lark-syntax'
	Plug 'dylon/vim-antlr'
	Plug 'beyondmarc/hlsl.vim'
	if has('patch-9.0.1767') == 0
		Plug 'peterhoeg/vim-qml'
	endif
	Plug 'neovimhaskell/haskell-vim'
	Plug 'preservim/vim-markdown'

	Plug 'tpope/vim-eunuch'
	Plug 'dag/vim-fish'
	Plug 'jamessan/vim-gnupg'

	Plug 'kana/vim-textobj-user'
	Plug 'kana/vim-textobj-syntax'
	Plug 'kana/vim-textobj-function', { 'for':['c', 'cpp', 'vim', 'java'] }
	Plug 'bps/vim-textobj-python', {'for': 'python'}
	Plug 'jceb/vim-textobj-uri'
	Plug 'sgur/vim-textobj-parameter'

	if mapcheck('ii', 'v') == ''
		Plug 'kana/vim-textobj-indent'
	endif

	if has_key(s:enabled, 'targets')
		Plug 'wellle/targets.vim'
		IncScript site/bundle/targets.vim
	endif

	if !has_key(s:enabled, 'syntax-extra')
		Plug 'octol/vim-cpp-enhanced-highlight', { 'for': ['c', 'cpp'] }
	else
		Plug 'justinmk/vim-syntax-extra', { 'for': ['c', 'bison', 'flex', 'cpp'] }
	endif
	
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
	" let g:cpp_no_function_highlight = 1
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
	Plug 'xolox/vim-notes', { 'on': ['Note', 'SearchNotes', 'DeleteNotes', 'RecentNotes'] }
	Plug 'skywind3000/vimoutliner', { 'for': 'votl' }
	" Plug 'vimoutliner/vimoutlliner', { 'for': 'votl' }
	Plug 'mattn/webapi-vim'
	Plug 'mattn/gist-vim'
	Plug 'hrj/vim-DrawIt'
	Plug 'lambdalisue/vim-gista', { 'on': 'Gista' }
	if v:version >= 800 || has('nvim')
		Plug 'rbong/vim-flog', { 'branch': 'v1' }
	endif

	if 1
		Plug 'inkarkat/vim-ingo-library'
		Plug 'inkarkat/vim-mark'
	else
		Plug 'lifepillar/vim-cheat40',
	endif

	" Plug 'Yggdroot/indentLine'
	
	IncScript site/bundle/outliner.vim

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
	Plug 'jreybert/vimagit'
	Plug 'cohama/agit.vim'

	" Plug 'tpope/vim-apathy'
	" Plug 'mh21/errormarker.vim'

	if 1
		" vimscript development
		Plug 'mhinz/vim-lookup'
		Plug 'tweekmonster/helpful.vim'
	endif

	if 1
		Plug 'AndrewRadev/switch.vim'
		IncScript site/bundle/switch.vim
	endif

	if 1
		Plug 'mattn/emmet-vim',  { 'on': 'EmmetInstall' }
		IncScript site/bundle/emmet.vim
	endif

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
		" Plug 'ludovicchabant/vim-gutentags'
		Plug 'skywind3000/vim-gutentags'
	endif

	if s:uname == 'windows' 
		let g:python3_host_prog="python"
	endif

	if 1
		" Echo translation in the cmdline
		nmap <silent> <Leader>ts <Plug>Translate
		vmap <silent> <Leader>ts <Plug>TranslateV
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
" modules 
"----------------------------------------------------------------------

" gdb
if has_key(s:enabled, 'gdb')
	IncScript site/bundle/gdb.vim
endif

" endwise
if has_key(s:enabled, 'endwise')
	Plug 'tpope/vim-endwise'
endif

" snippet
if has_key(s:enabled, 'snipmate')
	Plug 'MarcWeber/vim-addon-mw-utils'
	Plug 'tomtom/tlib_vim'
	Plug 'garbas/vim-snipmate'
	IncScript site/bundle/snipmate.vim
elseif has_key(s:enabled, 'ultisnips') && (has('python3') || has('python'))
	Plug 'SirVer/ultisnips'
	IncScript site/bundle/ultisnips.vim
elseif has_key(s:enabled, 'minisnip')
	Plug 'Jorengarenar/miniSnip'
	IncScript site/bundle/minisnip.vim
elseif has_key(s:enabled, 'neosnippet')
	Plug 'Shougo/neosnippet.vim'
	let s:enabled.neovim = 1
	IncScript site/bundle/neosnippet.vim
endif

" vim-go
if has_key(s:enabled, 'vim-go')
	Plug 'fatih/vim-go'
	IncScript site/bundle/go.vim
endif

if has_key(s:enabled, 'devdocs')
	if !has('nvim') && v:version >= 901
		Plug 'girishji/devdocs.vim'
		IncScript site/bundle/devdocs.vim
	endif
endif


" CoC
if has_key(s:enabled, 'coc')
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	IncScript site/bundle/coc.vim
endif

" vim-lsp
if has_key(s:enabled, 'lsp')
	Plug 'prabirshrestha/vim-lsp'
	Plug 'prabirshrestha/asyncomplete.vim'
	Plug 'prabirshrestha/asyncomplete-lsp.vim'
	Plug 'mattn/vim-lsp-settings'
	Plug 'prabirshrestha/asyncomplete-buffer.vim'
	Plug 'prabirshrestha/asyncomplete-tags.vim'
	Plug 'jsit/asyncomplete-user.vim'
	IncScript site/bundle/lsp.vim
endif

" copilot.vim
if has_key(s:enabled, 'copilot')
	Plug 'github/copilot.vim'
	IncScript site/bundle/copilot.vim
endif

" vimspector
if has_key(s:enabled, 'vimspector')
	Plug 'puremourning/vimspector'
	IncScript site/bundle/vimspector.vim
endif

" NeoDebug
if has_key(s:enabled, 'neodebug')
	Plug 'skywind3000/NeoDebug'
	IncScript site/bundle/neodebug.vim
endif

" echodoc
if has_key(s:enabled, 'echodoc')
	Plug 'Shougo/echodoc.vim'
	set noshowmode
	let g:echodoc#enable_at_startup = 1
endif

" lightline
if has_key(s:enabled, 'lightline')
	Plug 'itchyny/lightline.vim'
	IncScript site/bundle/lightline.vim
endif

" ale
if has_key(s:enabled, 'ale')
	Plug 'w0rp/ale'
	IncScript site/bundle/ale.vim
endif

if has_key(s:enabled, 'matchup')
	Plug 'andymass/vim-matchup'
	" vim-matchup conflicts with matchit, should disable matchit
	let g:loaded_matchit = 1
	IncScript site/bundle/matchup.vim
else
	runtime! macros/matchit.vim
endif

" vimwiki
if has_key(s:enabled, 'vimwiki')
	Plug 'vimwiki/vimwiki'
	IncScript site/bundle/vimwiki.vim
endif

" airline
if has_key(s:enabled, 'airline')
	Plug 'vim-airline/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	IncScript site/bundle/airline.vim
endif

if has_key(s:enabled, 'neovim')
	if !has('nvim')
		Plug 'roxma/nvim-yarp'
		Plug 'roxma/vim-hug-neovim-rpc'
	endif
endif

if has_key(s:enabled, 'floaterm')
	Plug 'voldikss/vim-floaterm'
	IncScript site/bundle/floaterm.vim
endif

if has_key(s:enabled, 'vim-doge')
	Plug 'kkoomen/vim-doge'
	IncScript site/bundle/doge.vim
endif

if has_key(s:enabled, 'nerdtree')
	Plug 'preservim/nerdtree', {'on': ['NERDTree', 'NERDTreeFocus', 'NERDTreeToggle', 'NERDTreeCWD', 'NERDTreeFind'] }
	Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
	IncScript site/bundle/nerdtree.vim
endif

if has_key(s:enabled, 'grammer')
	Plug 'rhysd/vim-grammarous'
	nnoremap <space>rg :GrammarousCheck --lang=en-US --no-move-to-first-error --no-preview<cr>
	nmap <space>rr <Plug>(grammarous-open-info-window)
	nmap <space>rv <Plug>(grammarous-move-to-info-window)
	nmap <space>rs <Plug>(grammarous-reset)
	nmap <space>rx <Plug>(grammarous-close-info-window)
	nmap <space>rm <Plug>(grammarous-remove-error)
	nmap <space>rd <Plug>(grammarous-disable-rule)
	nmap <space>rn <Plug>(grammarous-move-to-next-error)
	nmap <space>rp <Plug>(grammarous-move-to-previous-error)
endif

if has_key(s:enabled, 'neomake')
	Plug 'neomake/neomake'
endif

if has_key(s:enabled, 'vista')
	Plug 'liuchengxu/vista.vim'
endif

if has_key(s:enabled, 'defx')
	if has('nvim')
		Plug 'Shougo/defx.nvim', { 'do': ':UpdateRemotePlugins' }
	else
		Plug 'Shougo/defx.nvim'
		Plug 'roxma/nvim-yarp'
		Plug 'roxma/vim-hug-neovim-rpc'
	endif
	IncScript site/bundle/defx.vim
endif

if has_key(s:enabled, 'editorconfig')
	Plug 'editorconfig/editorconfig-vim'
endif

if has_key(s:enabled, 'neoterm')
	Plug 'kassio/neoterm'
endif

if has_key(s:enabled, 'clap')
	if !has('nvim')
		Plug 'liuchengxu/vim-clap'
		IncScript site/bundle/clap.vim
	endif
endif

if has_key(s:enabled, 'splitjoin')
	Plug 'AndrewRadev/splitjoin.vim'
endif

if has_key(s:enabled, 'neocomplete')
	if !has('patch-8.2.1065')
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
	else
		echohl ErrorMsg
		echom 'ERROR: neocomplete is incompatible with vim-8.2.1065+'
		echohl None
	endif
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

if has_key(s:enabled, 'tabnine')
	Plug 'codota/tabnine-vim'
	IncScript site/bundle/tabnine.vim
endif

if has_key(s:enabled, 'colors')
	Plug 'mhartington/oceanic-next'
	Plug 'soft-aesthetic/soft-era-vim'
	Plug 'sonph/onehalf', {'rtp': 'vim/'}
	Plug 'sainnhe/sonokai'
	Plug 'sainnhe/everforest'
	Plug 'chuling/ci_dark'
	Plug 'arcticicestudio/nord-vim'
	Plug 'romainl/Apprentice'
	Plug 'arzg/vim-colors-xcode'
    Plug 'wuelnerdotexe/vim-enfocado'
	Plug 'kaicataldo/material.vim'
	Plug 'cocopon/iceberg.vim'
	Plug 'mcchrish/zenbones.nvim'
	Plug 'rafi/awesome-vim-colorschemes'
	Plug 'skywind3000/vim-colorschemes'
	Plug 'jaredgorski/SpaceCamp'
	Plug 'mswift42/vim-themes'
	if !has('nvim')
		Plug 'skywind3000/colors-from-neovim.vim'
	endif
	IncScript site/bundle/colors.vim
endif

if has_key(s:enabled, 'games')
	Plug 'iqxd/vim-mine-sweeping'
	Plug 'vim-scripts/Mines'
	Plug 'katono/rogue.vim'
endif

if has_key(s:enabled, 'whichkey')
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
	let g:cursorword = 0
endif

if has_key(s:enabled, 'anyjump')
	Plug 'pechorin/any-jump.vim'
endif

if has_key(s:enabled, 'notify')
	if has('nvim')
		Plug 'rcarriga/nvim-notify'
	endif
endif

if has_key(s:enabled, 'snippets')
	Plug 'honza/vim-snippets'
endif

if has_key(s:enabled, 'tagbar')
	Plug 'preservim/tagbar'
endif

if has_key(s:enabled, 'lh-cpp')
	Plug 'LucHermitte/lh-vim-lib'
	Plug 'LucHermitte/lh-style'
	Plug 'LucHermitte/lh-tags'
	Plug 'LucHermitte/lh-dev'
	Plug 'LucHermitte/lh-brackets'
	Plug 'LucHermitte/searchInRuntime'
	Plug 'LucHermitte/mu-template'
	Plug 'tomtom/stakeholders_vim'
	Plug 'LucHermitte/alternate-lite'
	Plug 'LucHermitte/lh-cpp'
endif


"----------------------------------------------------------------------
" packages end
"----------------------------------------------------------------------
if exists('g:bundle_post')
	if type(g:bundle_post) == type('')
		exec g:bundle_post
	elseif type(g:bundle_post) == type([])
		exec join(g:bundle_post, "\n")
	endif
endif

call plug#end()


"----------------------------------------------------------------------
" move s:home to the top of rtp
"----------------------------------------------------------------------
if get(g:, 'reorder_rtp', 0)
	let rtps = split(&rtp, ',')
	let rtps = [s:home] + rtps
	let &rtp = ''
	for n in rtps | exec 'set rtp+=' . fnameescape(n) | endfor
endif



