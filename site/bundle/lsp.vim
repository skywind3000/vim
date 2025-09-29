" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" lsp.vim - LSP config
"
" Created by skywind on 2022/12/05
" Last Modified: 2022/12/06 03:51
"
"======================================================================


"----------------------------------------------------------------------
" turning lsp
"----------------------------------------------------------------------
let g:lsp_use_lua = has('nvim-0.4.0') || (has('lua') && has('patch-8.2.0775'))
let g:lsp_completion_documentation_enabled = 0
let g:lsp_diagnostics_enabled = 0
let g:lsp_diagnostics_signs_enabled = 0
let g:lsp_diagnostics_highlights_enabled = 0
let g:lsp_document_code_action_signs_enabled = 0

let g:lsp_signature_help_enabled = 0
let g:lsp_document_highlight_enabled = 1
let g:lsp_preview_fixup_conceal = 1
let g:lsp_hover_conceal = 1

let g:lsp_settings_root_markers = ['.git', '.git/', '.svn', '.svn/',
			\ '.root', '.root/', '.project']


"----------------------------------------------------------------------
" turning completion
"----------------------------------------------------------------------
let g:asyncomplete_min_chars = 2
let g:asyncomplete_auto_completeopt = 0
let g:asyncomplete_auto_popup = 1

set shortmess+=c


"----------------------------------------------------------------------
" keymaps
"----------------------------------------------------------------------
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr> pumvisible() ? asyncomplete#close_popup() . "\<cr>" : "\<cr>"

function! s:check_back_space() abort
	let col = col('.') - 1
	return !col || getline('.')[col - 1]  =~ '\s'
endfunc

inoremap <silent><expr> <TAB>
			\ pumvisible() ? "\<C-n>" :
			\ <SID>check_back_space() ? "\<TAB>" :
			\ asyncomplete#force_refresh()

function! s:force_refresh()
	" call feedkeys("\<Plug>(asyncomplete_force_refresh)", 'm')
	call feedkeys("\<tab>", 'm')
	" call feedkeys("\<tab>", 'n')
	unsilent echom "refresh"
	return ''
endfunc

" imap <silent><expr> . "." . <SID>force_refresh()
" inoremap <silent><expr> > pumvisible() ? ">" : ">" . "\<Plug>(asyncomplete_force_refresh)"
" inoremap <silent><expr> : pumvisible() ? ":" : ":" . "\<Plug>(asyncomplete_force_refresh)"


"----------------------------------------------------------------------
" initialize lsp
"----------------------------------------------------------------------
function! s:initialize_lsp() abort
	let lsp_servers = get(g:, 'lsp_servers', {})
	let s:rootmarkers = {}
	for name in keys(lsp_servers)
		let info = lsp_servers[name]
		let ni = {}
		let ni.name = name
		let ni.cmd = [info.path] + get(info, 'args', [])
		let ni.allowlist = get(info, 'filetype', [])
		let ni.initialization_options = get(info, 'options', {})
		let ni.workspace_config = get(info, 'config', {})
		let root = get(info, 'root', [])
		if len(root) > 0
			let rootmarkers = []
			for marker in root
				call add(rootmarkers, marker)
				call add(rootmarkers, marker . '/')
			endfor
			let s:rootmarkers[name] = rootmarkers
			let ni.root_uri = {server_info -> lsp#utils#path_to_uri(
						\ lsp#utils#find_nearest_parent_file_directory(
						\ lsp#utils#get_buffer_path(),
						\ rootmarkers))}
		endif
		call lsp#register_server(ni)
	endfor
	call s:initialize_ft()
endfunc


"----------------------------------------------------------------------
" initialize complete
"----------------------------------------------------------------------
function! s:initialize_complete() abort
	let lsp_servers = get(g:, 'lsp_servers', {})
	let disable = {}
	for name in keys(lsp_servers)
		let info = lsp_servers[name]
		for ft in get(info, 'filetype', [])
			let disable[ft] = 1
		endfor
	endfor
	let blacklist = keys(disable)
	call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
				\ 'name': 'buffer',
				\ 'allowlist': ['*'],
				\ 'blocklist': blacklist,
				\ 'completor': function('asyncomplete#sources#buffer#completor'),
				\ 'config': {
				\    'max_buffer_size': 5000000,
				\  },
				\ }))
	" call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
	" 			\ 'name': 'file',
	" 			\ 'allowlist': ['*'],
	" 			\ 'blocklist': blacklist,
	" 			\ 'completor': function('asyncomplete#sources#file#completor'),
	" 			\ 'priority': 10,
	" 			\ }))
	call s:initialize_ft()
endfunc


"----------------------------------------------------------------------
" initialize filetype
"----------------------------------------------------------------------
function! s:initialize_ft() abort
	if exists('g:lsp_servers') && exists('s:enabled') == 0
		let lsp_servers = get(g:, 'lsp_servers', {})
		let enabled = {}
		for name in keys(lsp_servers)
			let info = lsp_servers[name]
			for ft in get(info, 'filetype', [])
				let enabled[ft] = 1
			endfor
		endfor
		let s:enabled = enabled
	endif
	if exists('s:enabled')
		if has_key(s:enabled, &ft)
			set omnifunc=lsp#complete
			inoremap <silent><buffer><expr> . ".\<c-x>\<c-o>"
			inoremap <silent><buffer><expr> > ">\<c-x>\<c-o>"
			inoremap <silent><buffer><expr> : ":\<c-x>\<c-o>"
		endif
	endif
endfunc


"----------------------------------------------------------------------
" autocommands
"----------------------------------------------------------------------
augroup PrabirshresthaLspListener
	au!
	autocmd User lsp_setup call s:initialize_lsp()
	autocmd User asyncomplete_setup call s:initialize_complete()
	autocmd FileType * call s:initialize_ft()
	autocmd InsertEnter * setlocal omnifunc=lsp#complete
augroup END


"----------------------------------------------------------------------
" popup
"----------------------------------------------------------------------
hi! PopupWindow ctermbg=236 guibg=#303030

function! s:preview_open()
	let wid = lsp#document_hover_preview_winid()
	hi! PopupWindow ctermbg=236 guibg=#303030
	" echom "popup opened"
	if has('nvim') == 0
		call setwinvar(wid, '&wincolor', 'PopupWindow')
		" call win_execute(wid, 'syn clear')
		" call win_execute(wid, 'unsilent echom "ft: " . &ft')
	else
		call nvim_win_set_option(wid, 'winhighlight', 'Normal:PopupWindow')
	endif
endfunc

function! s:preview_close()
endfunc

augroup Lsp_FloatColor2
	au!
	autocmd User lsp_float_opened call s:preview_open()
	autocmd User lsp_float_closed call s:preview_close()
augroup END


