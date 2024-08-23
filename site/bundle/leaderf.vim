"======================================================================
"
" init_leaderf.vim - 
"
" Created by skywind on 2020/03/01
" Last Modified: 2020/03/01 04:43:07
"
"======================================================================


"----------------------------------------------------------------------
" keymap
"----------------------------------------------------------------------
let g:Lf_ShortcutF = '<c-p>'
let g:Lf_ShortcutB = '<m-n>'
let g:Lf_MruMaxFiles = 2048
let g:Lf_StlSeparator = { 'left': '', 'right': '', 'font': '' }
" let g:Lf_PreviewHorizontalPosition = 'center'
let g:Lf_PopupPreviewPosition='bottom'
let g:Lf_PreviewInPopup = 0
let g:Lf_QuickSelect = 1
let g:Lf_QuickSelectAction = 't'
let g:Lf_GtagsAutoUpdate = 0

noremap <m-g> :Leaderf --nowrap tasks<cr>
inoremap <m-g> <esc>:Leaderf --nowrap tasks<cr>

if has('gui_running')
	" noremap <c-f12> :Leaderf --nowrap tasks<cr>
	" inoremap <c-f12> <esc>:Leaderf --nowrap tasks<cr>
endif


"----------------------------------------------------------------------
" LeaderF
"----------------------------------------------------------------------
let g:Lf_RootMarkers = ['.project', '.root', '.svn', '.git']
let g:Lf_WorkingDirectoryMode = 'Ac'
let g:Lf_WindowHeight = 0.30
let g:Lf_PopupWidth = 0.75
let g:Lf_CacheDirectory = expand('~/.vim/cache')
let g:Lf_ShowRelativePath = 1
let g:Lf_HideHelp = 1
let g:Lf_NoChdir = 1

let g:Lf_WildIgnore = {
            \ 'dir': ['.svn','.git','.hg'],
            \ 'file': ['*.sw?','~$*','*.bak','*.exe','*.o','*.so','*.py[co]']
			\ }

let g:Lf_MruFileExclude = ['*.so', '*.exe', '*.py[co]', '*.sw?', '~$*', '*.bak', '*.tmp', '*.dll']
let g:Lf_MruMaxFiles = 2048
let g:Lf_StlColorscheme = 'powerline'
let g:Lf_PopupColorscheme = 'default'
let g:Lf_PopupColorscheme = 'gruvbox_default'
let g:Lf_ShortcutF = '<c-p>'
let g:Lf_ShortcutB = '<m-n>'
let g:Lf_StlSeparator = { 'left': '', 'right': '', 'font': '' }
let g:Lf_PreviewResult = {'Function':0, 'BufTag':0}
let g:Lf_MruEnableFrecency = 1

let g:Lf_NormalMap = {
        \ "File":   [["<ESC>", ':exec g:Lf_py "fileExplManager.quit()"<CR>']],
		\ "Buffer": [["<ESC>", ':exec g:Lf_py "bufExplManager.quit()"<cr>']],
		\ "Mru": [["<ESC>", ':exec g:Lf_py "mruExplManager.quit()"<cr>']],
		\ "Tag": [["<ESC>", ':exec g:Lf_py "tagExplManager.quit()"<cr>']],
		\ "BufTag": [["<ESC>", ':exec g:Lf_py "bufTagExplManager.quit()"<cr>']],
		\ "Function": [["<ESC>", ':exec g:Lf_py "functionExplManager.quit()"<cr>']],
		\ }

if (exists('*popup_create') && has('patch-8.1.2000')) || has('nvim-0.4')
	let g:Lf_WindowPosition = 'popup'
endif

let g:Lf_PreviewInPopup = 1


"----------------------------------------------------------------------
" preview 
"----------------------------------------------------------------------
let g:Lf_PreviewResult = {
		\ 'File': 0,
		\ 'Buffer': 0,
		\ 'Mru': 0,
		\ 'Tag': 0,
		\ 'BufTag': 0,
		\ 'Function': 0,
		\ 'Line': 0,
		\ 'Colorscheme': 0,
		\ 'Rg': 0,
		\ 'Gtags': 0,
		\ 'Snippet': 0,
		\}


"----------------------------------------------------------------------
" filer
"----------------------------------------------------------------------
let g:Lf_FilerShowPromptPath = 1
let g:Lf_FilerInsertMap = { '<Tab>': 'open_current', '<CR>': 'open_current',
	\ '<BS>': 'open_parent_or_backspace', '<up>': 'up', '<down>': 'down'}
let g:Lf_FilerNormalMap = {'i': 'switch_insert_mode', '<esc>': 'quit', 
	\ '~': 'goto_root_marker_dir', 'M': 'mkdir', 'T': 'create_file' }
" let g:Lf_FilerOnlyIconHighlight = 1


"----------------------------------------------------------------------
" ctags options
"----------------------------------------------------------------------
let g:Lf_CtagsFuncOpts = {
			\ "dosini": "--iniconf-kinds=s --language-force=iniconf",
			\ "taskini": "--iniconf-kinds=s --language-force=iniconf",
			\ }


"----------------------------------------------------------------------
" keymap
"----------------------------------------------------------------------
if get(g:, 'lf_disable_normal_map', 0) == 0
	nnoremap <space>ff :<c-u>Leaderf file<cr>
	nnoremap <space>fe :<c-u>Leaderf filer<cr>
	nnoremap <space>fb :<c-u>Leaderf buffer<cr>
	nnoremap <space>fm :<c-u>Leaderf mru<cr>
	nnoremap <space>fg :<c-u>Leaderf gtags<cr>
	nnoremap <space>fr :<c-u>Leaderf rg<cr>
	" nnoremap <space>fw :<c-u>Leaderf window<cr>
	nnoremap <space>fn :<c-u>Leaderf function<cr>
	nnoremap <space>ft :<c-u>Leaderf tag<cr>
	nnoremap <space>fu :<c-u>Leaderf bufTag<cr>
	nnoremap <space>fs :<c-u>Leaderf self<cr>
	nnoremap <space>fc :<c-u>Leaderf colorscheme<cr>
	nnoremap <space>fy :<c-u>Leaderf cmdHistory<cr>
	" nnoremap <space>fh :<c-u>Leaderf help<cr>
	nnoremap <space>fj :<c-u>Leaderf jumps<cr>
	nnoremap <space>fp :<c-u>Leaderf snippet<cr>
	nnoremap <space>fq :<c-u>Leaderf quickfix<cr>
	nnoremap <space>fa :<c-u>Leaderf tasks<cr>
	" filer
	nnoremap <space>fd :exec 'Leaderf filer ' . shellescape(expand('%:p:h'))<cr>

	" basic keymaps
	noremap <c-n> :cclose<cr>:Leaderf --nowrap mru --regexMode<cr>
	noremap <m-p> :cclose<cr>:Leaderf! --nowrap function<cr>
	noremap <m-P> :cclose<cr>:Leaderf! --nowrap buftag<cr>
	noremap <m-n> :cclose<cr>:Leaderf! --nowrap buffer<cr>
	noremap <m-m> :cclose<cr>:Leaderf --nowrap tag<cr>
endif

if get(g:, 'lf_disable_snippet_map', 0) == 0
	inoremap <c-x><c-x> <c-\><c-o>:Leaderf snippet<cr>
endif



