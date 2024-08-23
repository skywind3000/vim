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


"----------------------------------------------------------------------
" turning completion
"----------------------------------------------------------------------
let g:asyncomplete_min_chars = 0
let g:asyncomplete_auto_completeopt = 0

set shortmess+=c


"----------------------------------------------------------------------
" popup
"----------------------------------------------------------------------
hi! PopupWindow ctermbg=236 guibg=#303030

function! s:preview_open()
	let wid = lsp#document_hover_preview_winid()
	hi! PopupWindow ctermbg=236 guibg=#303030
	echom "popup opened"
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

" inoremap <silent><expr> .  ("." . asyncomplete#force_refresh())


