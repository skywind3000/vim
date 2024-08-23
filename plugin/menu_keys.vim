"======================================================================
"
" menu_keys.vim - vim-navigator initialize
"
" Created by skywind on 2023/06/27
" Last Modified: 2024/03/24 18:43
"
"======================================================================

let g:navigator = {}
let g:navigator_visual = {}

let g:navigator.prefix = "<tab><tab>"
let g:navigator_visual.prefix = "<tab><tab>"


"----------------------------------------------------------------------
" buffer
"----------------------------------------------------------------------
let g:navigator.b = {
			\ 'name' : '+buffer' ,
			\ '1' : [':b1'        , 'buffer 1']        ,
			\ '2' : [':b2'        , 'buffer 2']        ,
			\ 'd' : [':bd'        , 'delete-buffer']   ,
			\ 'f' : [':bfirst'    , 'first-buffer']    ,
			\ 'h' : [':Startify'  , 'home-buffer']     ,
			\ 'l' : [':blast'     , 'last-buffer']     ,
			\ 'n' : [':bnext'     , 'next-buffer']     ,
			\ 'p' : [':bprevious' , 'previous-buffer'] ,
			\ '?' : [':Leaderf buffer'   , 'fzf-buffer']      ,
			\ }


"----------------------------------------------------------------------
" window
"----------------------------------------------------------------------
let g:navigator.w = {
			\ 'name': '+window',
			\ 'p': ['wincmd p', 'jump-previous-window'],
			\ 'h': ['wincmd h', 'jump-left-window'],
			\ 'j': ['wincmd j', 'jump-belowing-window'],
			\ 'k': ['wincmd k', 'jump-aboving-window'],
			\ 'l': ['wincmd l', 'jump-right-window'],
			\ 'H': ['wincmd H', 'move-window-to-left'],
			\ 'J': ['wincmd J', 'move-window-to-bottom'],
			\ 'K': ['wincmd K', 'move-window-to-top'],
			\ 'L': ['wincmd L', 'move-window-to-right'],
			\ 'n': ['wincmd n', 'new-window'],
			\ 'q': ['wincmd q', 'close-window'],
			\ 'w': ['wincmd w', 'jump-next-window'],
			\ 'o': ['wincmd o', 'close-all-other-windows'],
			\ 'v': ['wincmd v', 'vertically-split-window'],
			\ 's': ['wincmd s', 'split-window'],
			\ '1': ['1wincmd w', 'window-1'],
			\ '2': ['2wincmd w', 'window-2'],
			\ '3': ['3wincmd w', 'window-3'],
			\ '4': ['4wincmd w', 'window-4'],
			\ '5': ['5wincmd w', 'window-5'],
			\ '/': [':Leaderf window', 'search-for-a-window'],
			\ }


"----------------------------------------------------------------------
" tab
"----------------------------------------------------------------------
let g:navigator['<tab>'] = {
			\ 'name': '+tab',
			\ 'c' : [':tabnew', 'new-tab'],
			\ 'v' : [':tabclose', 'close-current-tab'],
			\ 'n' : [':tabnext', 'next-tab'],
			\ 'p' : [':tabprev', 'previous-tab'],
			\ 'o' : [':tabonly', 'close-all-other-tabs'],
			\ 'l' : [':tabmove -1', 'move-tab-left'],
			\ 'r' : [':tabmove +1', 'move-tab-right'],
			\ 'L' : [':CloseLeftTabs', 'close-left-tabs'],
			\ 'R' : [':CloseRightTabs', 'close-right-tabs'],
			\ '0' : [':tabn 10', 'tab-10'],
			\ '1' : ['<key>1gt', 'tab-1'],
			\ '2' : ['<key>2gt', 'tab-2'],
			\ '3' : ['<key>3gt', 'tab-3'],
			\ '4' : ['<key>4gt', 'tab-4'],
			\ '5' : ['<key>5gt', 'tab-5'],
			\ '6' : ['<key>6gt', 'tab-6'],
			\ '7' : ['<key>7gt', 'tab-7'],
			\ '8' : ['<key>8gt', 'tab-8'],
			\ '9' : ['<key>9gt', 'tab-9'],
			\ }


"----------------------------------------------------------------------
" search
"----------------------------------------------------------------------
let g:navigator.s = {
			\ 'name': '+search',
			\ 's': ['MenuHelp_Fscope("s")', 'gscope-find-symbol'],
			\ 'g': ['MenuHelp_Fscope("g")', 'gscope-find-definition'],
			\ 'c': ['MenuHelp_Fscope("c")', 'gscope-find-calling'],
			\ 'd': ['MenuHelp_Fscope("d")', 'gscope-find-called'],
			\ 'e': ['MenuHelp_Fscope("e")', 'gscope-find-pattern'],
			\ 't': ['MenuHelp_Fscope("t")', 'gscope-find-text'],
			\ 'a': ['MenuHelp_Fscope("a")', 'gscope-find-assigned'],
			\ 'f': ['MenuHelp_Fscope("f")', 'gscope-find-file'],
			\ 'i': ['MenuHelp_Fscope("i")', 'gscope-find-include'],
			\ 'z': ['MenuHelp_Fscope("z")', 'gscope-find-ctags'],
			\ }


"----------------------------------------------------------------------
" open
"----------------------------------------------------------------------
let g:navigator.o = {
			\ 'name': '+open-files',
			\ 'r' : [':Leaderf mru', 'leaderf-recent-files'],
			\ 'p' : [':Leaderf mru', 'leaderf-project-files'],
			\ 'f' : [':EditFileTypeScript', 'open-file-type-script'],
			\ 'w' : [':VimwikiTabIndex', 'open-wiki'],
			\ 'g' : [':FileSwitch ~/.gitconfig', 'open-gitconfig'],
			\ }


"----------------------------------------------------------------------
" language
"----------------------------------------------------------------------
let g:navigator.l = {
			\ 'name': '+language',
			\ }

	
"----------------------------------------------------------------------
" project
"----------------------------------------------------------------------
let g:navigator.p = {
			\ 'name': '+project',
			\ ';' : ['CdToProjectRoot', 'cd-to-project-root'],
			\ '-' : ['module#action#shell()', 'run-shell-command'],
			\ '.' : ['module#project#init(1)', 'init-project-root'],
			\ 'e' : ['module#project#open("CMakeLists.txt")', 'edit-cmake-lists'],
			\ 't' : [':AsyncTaskEdit', 'edit-task-list'],
			\ 'd' : ['module#project#open("README.md")', 'edit-readme-md'],
			\ 'i' : ['module#project#open(".gitignore")', 'edit-git-ignore'],
			\ 'c' : ['module#project#open(".clangd")', 'edit-clangd-config'],
			\ 'l' : ['module#project#try_open(".git/config")', 'edit-git-config'],
			\ 'r' : ['module#project#open(".lvimrc")', 'edit-local-vimrc'],
			\ 'g' : ['module#project#open("go.mod")', 'edit-go-mod'],
			\ 'm' : ['module#project#open("Makefile")', 'edit-makefile'],
			\ }


"----------------------------------------------------------------------
" LSP
"----------------------------------------------------------------------
let g:navigator.L = {
			\ 'name': '+lsp',
			\ }


"----------------------------------------------------------------------
" wsl
"----------------------------------------------------------------------
if has('win32') || has('win64')
	let g:navigator.W = {
				\ 'name': '+linux-wsl',
				\ 'b': [':AsyncTask wsl-project-build', 'wsl-project-build'],
				\ 'i': [':AsyncTask wsl-project-init', 'wsl-project-init'],
				\ 'r': [':AsyncTask wsl-project-run', 'wsl-project-run'],
				\ 't': [':AsyncTask wsl-project-test', 'wsl-project-test'],
				\ 'g': [':AsyncTask wsl-file-build', 'wsl-file-build'],
				\ 'f': [':AsyncTask wsl-file-run', 'wsl-file-run'],
				\ }
elseif 1
endif
	

"----------------------------------------------------------------------
" help
"----------------------------------------------------------------------
let g:navigator.h = {
			\ 'name': '+help',
			\ 'b' : [':Help bash', 'bash-cheatsheet'],
			\ 'v' : [':Help vim', 'vim-cheatsheet'],
			\ 'G' : [':Help gdb', 'gdb-cheatsheet'],
			\ 'g' : [':Help git', 'git-cheatsheet'],
			\ 'n' : [':Help nano', 'nano-cheatsheet'],
			\ }


"----------------------------------------------------------------------
" YouCompleteMe
"----------------------------------------------------------------------
let g:navigator.y = {
			\ 'name': '+ycm',
			\ }


"----------------------------------------------------------------------
" emake
"----------------------------------------------------------------------
let g:navigator.e = {
			\ 'name': '+emake',
			\ 'C': ['module#misc#emake_config()', 'emake-config-change'],
			\ 'c': [':AsyncTask emake-clean', 'emake-clean'],
			\ 'p': [':AsyncTaskEnviron profile debug release static', 'emake-profile-change'],
			\ 'o': [':split ~/.config/emake/', 'open-config-directory'],
			\ 'e': ['module#misc#open("~/.config/emake.ini")', 'edit-global-config'],
			\ }


"----------------------------------------------------------------------
" escript runner
"----------------------------------------------------------------------
let g:navigator.r = {
			\ 'name': '+escript-runner',
			\ 'l' : ['EScript list_rtp', 'list-runtime-path'],
			\ 'p' : ['EScript lua_package', 'list-lua-package'],
			\ 's' : ['EScript script_names', 'list-loaded-scripts'],
			\ }


"----------------------------------------------------------------------
" coding
"----------------------------------------------------------------------
let g:navigator.c = {
			\ 'name' : '+coding',
			\ 
			\ }


"----------------------------------------------------------------------
" Easymotion
"----------------------------------------------------------------------
let g:navigator.m = ['module#compat#easymotion_word()', 'easy-motion-bd-w']
let g:navigator.n = ['<plug>(easymotion-s)', 'easy-motion-s']


"----------------------------------------------------------------------
" misc
"----------------------------------------------------------------------
if has('win32') || has('win64')
	let g:navigator[','] = [':OpenShell cmdclink', 'open-cmd-here']
	let g:navigator['-'] = [':OpenShell explorer', 'open-explorer-here']
endif

let g:navigator[';'] = ['bufferhint#Popup()', 'open-buffer-hint']
let g:navigator["."] = ['<plug>(choosewin)', 'switch-tab-window']


"----------------------------------------------------------------------
" extension
"----------------------------------------------------------------------
let g:navigator.x = {
			\ 'name': '+extension',
			\ 's': [':syntax sync fromstart', 'sync-syntax-fromstart'],
			\ 'i': ['<key>:tabonly<cr>:h index<cr><c-w>o<c-w>v<space>hk', 'init-layout'],
			\ 'h': [':DisplayHighlightGroup', 'display-highlight-group'],
			\ 't': ['<plug>TranslateW', 'translate-current-word'],
			\ 'm': [':messages', 'messages-list'],
			\ 'M': [':messages clear', 'messages-clear'],
			\ 'd': [':LocalRcDisplay', 'display-localrc-messages'],
			\ 'z': [':AsyncTask git-lazygit', 'lazygit'],
			\ }


"----------------------------------------------------------------------
" VISUAL mode
"----------------------------------------------------------------------
let g:navigator_visual['='] = ['<key>=', 'indent-block']
let g:navigator_visual['*'] = ['<key>*', 'search-selected-text']
" let g:navigator_visual['r'] = ['<key>>', 'move-right']
" let g:navigator_visual['l'] = ['<key><', 'move-left']

let g:navigator_visual.a = {
			\ 'name': '+align-selected-text',
			\ '=': [':Tabularize /=', 'align-to-equal'],
			\ ':': [':Tabularize /:', 'align-to-colon'],
			\ '/': [':Tabularize /\/\//l4c1', 'align-to-cpp-comment'],
			\ '*': [':Tabularize /\/\*/l4c1', 'align-to-c-comment'],
			\ ',': [':Tabularize /,/r0l1', 'align-to-comma'],
			\ 'l': [':Tabularize /\|', 'align-to-bar'],
			\ '#': [':Tabularize /#/l4c1', 'align-to-sharp'],
			\ }

let g:navigator_visual.t = {
			\ 'name': '+text-filter',
			\ 'j' : ['TP format_json', 'format-json'],
			\ 'h' : ['TP format_html', 'format-html'],
			\ 'm' : ['TP html2markdown', 'html-to-markdown'],
			\ 't' : ['TP html_to_text', 'html-to-text'],
			\ 'r' : ['TP remove_markdown_links', 'remove-markdown-links'],
			\ 's' : ['TP comment_surround', 'comment-surround-block'],
			\ }

let g:navigator_visual.p = {
			\ 'name': '+filter-preview',
			\ 'j' : ['TP! format_json', 'preview-format-json'],
			\ 'h' : ['TP! format_html', 'preview-format-html'],
			\ 'm' : ['TP! html2markdown', 'preview-html-to-markdown'],
			\ 't' : ['TP! html_to_text', 'preview-html-to-text'],
			\ 'r' : ['TP! remove_markdown_links', 'remove-markdown-links'],
			\ 's' : ['TP! comment_surround', 'comment-surround-block'],
			\ }

let g:navigator_visual.c = {
			\ 'name': '+coding',
			\ 'b' : ['CppBraceExpand', 'cpp-brace-expand'],
			\ 'c' : ['CppClassInsert', 'cpp-class-insert'],
			\ }

let g:navigator_visual.f = {
			\ 'name': '+format',
			\ 'f' : ['<key>gq', 'format-with-formatprg'],
			\ }

let g:navigator_visual.m = ['<plug>MarkSet', 'mark-selected']
let g:navigator.M = [':MarkClear', 'mark-clear']

let g:navigator_visual.x = {
			\ 'name': '+extension',
			\ 't': ['<Plug>Translate', 'translate-selected'],
			\ }


" let g:navigator_visual.config = {'popup':1, 'popup_position':'center'}


"----------------------------------------------------------------------
" INSERT mode
"----------------------------------------------------------------------
let g:navigator_insert = {}
let g:navigator_insert.prefix = '<c-\><c-\>'

let g:navigator_insert.x = [':Leaderf snippet', 'snippet-select']

let g:navigator_insert.s = {
			\ 'name': '+snippet',
			\ 't' : ['echo 123', 'test-123'],
			\ }

let g:navigator_insert.i = {
			\ 'name': '+insert-text',
			\ 'd': ['<key><c-r>=strftime("%Y-%m-%d")<cr>', 'insert-year-month-day'],
			\ 't': ['<key><c-r>=strftime("%H:%M:%S")<cr>', 'insert-hour-minute-sec'],
			\ 'c': ['<key><c-r>=expand("%:t:r")<cr>', 'insert-class-name'],
			\ 'h': [':CodeSnipExpand head', 'insert-head'],
			\ 'b': [':CodeSnipExpand block', 'insert-block'],
			\ }

let g:navigator_insert.j = [':ToggleJapaneseKeymap', 'toggle-japanese-keymap']


"----------------------------------------------------------------------
" trigger
"----------------------------------------------------------------------
nnoremap <silent><tab><tab> :Navigator *:navigator<cr>
vnoremap <silent><tab><tab> :NavigatorVisual *:navigator_visual<cr>
inoremap <silent><c-\><c-\> <c-\><c-o>:Navigator *:navigator_insert<cr>


