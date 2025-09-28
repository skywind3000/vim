"======================================================================
"
" lsp9.vim - yegappan/lsp configuration
"
" Created by skywind on 2025/09/28
" Last Modified: 2025/09/28 15:56:42
"
"======================================================================

"----------------------------------------------------------------------
" configuration
"----------------------------------------------------------------------
let s:lsp_opts = #{
		\   aleSupport: v:false,
        \   autoComplete: v:true,
        \   autoHighlight: v:false,
        \   autoHighlightDiags: v:false,
        \   autoPopulateDiags: v:false,
        \   completionMatcher: 'case',
        \   completionMatcherValue: 1,
        \   diagSignErrorText: 'E>',
        \   diagSignHintText: 'H>',
        \   diagSignInfoText: 'I>',
        \   diagSignWarningText: 'W>',
        \   echoSignature: v:true,
        \   hideDisabledCodeActions: v:false,
        \   highlightDiagInline: v:true,
        \   hoverInPreview: v:false,
        \   ignoreMissingServer: v:false,
        \   keepFocusInDiags: v:true,
        \   keepFocusInReferences: v:true,
        \   completionTextEdit: v:true,
        \   diagVirtualTextAlign: 'above',
        \   diagVirtualTextWrap: 'default',
        \   noNewlineInCompletion: v:false,
        \   omniComplete: v:true,
        \   outlineOnRight: v:false,
        \   outlineWinSize: 20,
        \   popupBorder: v:true,
        \   popupBorderHighlight: 'Title',
        \   popupBorderHighlightPeek: 'Special',
        \   popupBorderSignatureHelp: v:false,
        \   popupHighlightSignatureHelp: 'Pmenu',
        \   popupHighlight: 'Normal',
        \   semanticHighlight: v:true,
        \   showDiagInBalloon: v:true,
        \   showDiagInPopup: v:true,
        \   showDiagOnStatusLine: v:false,
        \   showDiagWithSign: v:true,
        \   showDiagWithVirtualText: v:false,
        \   showInlayHints: v:false,
        \   showSignature: v:true,
        \   snippetSupport: v:false,
        \   ultisnipsSupport: v:false,
        \   useBufferCompletion: v:false,
        \   usePopupInCodeAction: v:false,
        \   useQuickfixForLocations: v:false,
        \   vsnipSupport: v:false,
        \   bufferCompletionTimeout: 100,
        \   customCompletionKinds: v:false,
        \   completionKinds: {},
        \   filterCompletionDuplicates: v:true,
        \   condensedCompletionMenu: v:false,
        \ }


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:lsp_servers = []


"----------------------------------------------------------------------
" check_back_space 
"----------------------------------------------------------------------
function! s:check_back_space() abort
	  return col('.') < 2 || getline('.')[col('.') - 2]  =~# '\s'
endfunc


"----------------------------------------------------------------------
" TAB initialize
"----------------------------------------------------------------------
inoremap <silent><expr> <TAB> 
			\ pumvisible()? "\<c-n>" : 
			\ <SID>check_back_space()? "\<tab>" :
			\ "\<c-x>\<c-o>"

inoremap <silent><expr> <S-TAB> pumvisible()? "\<c-p>" : "\<s-tab>"


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
function! s:init_lsp()
	let l:lsp_opts = deepcopy(s:lsp_opts)
	let l:lsp_servers = deepcopy(s:lsp_servers)
	if exists('g:lsp9_opts')
		for key in keys(g:lsp9_opts)
			let l:lsp_opts[key] = g:lsp9_opts[key]
		endfor
	endif
	call LspOptionsSet(l:lsp_opts)
	if exists('g:lsp9_servers')
		for key in keys(g:lsp9_servers)
			let item = deepcopy(g:lsp9_servers[key])
			let item.name = key
			call add(l:lsp_servers, item)
		endfor
	endif
	call LspAddServer(l:lsp_servers)
endfunc


"----------------------------------------------------------------------
" autocmd
"----------------------------------------------------------------------
augroup YegappanLspInit
	au! 
	autocmd User LspSetup call s:init_lsp()
augroup END


