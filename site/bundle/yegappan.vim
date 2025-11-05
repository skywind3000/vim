"======================================================================
"
" yegappan.vim - yegappan/lsp configuration
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
        \   completionMatcher: 'fuzzy',
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
        \   semanticHighlight: v:false,
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
function! s:init_lsp() abort
	let l:lsp_opts = deepcopy(s:lsp_opts)
	let l:lsp_servers = get(g:, 'lsp_servers', {})
	if exists('g:yegappan_opts')
		for key in keys(g:yegappan_opts)
			let l:lsp_opts[key] = g:yegappan_opts[key]
		endfor
	endif
	call LspOptionsSet(l:lsp_opts)
	let servers = []
	for name in keys(l:lsp_servers)
		let info = l:lsp_servers[name]
		let ni = {}
		let ni.name = name
		let ni.path = get(info, 'path', '')
		let ni.args = get(info, 'args', [])
		if has_key(info, 'filetype')
			let ni.filetype = info.filetype
		endif
		if has_key(info, 'options')
			let ni.initializationOptions = info.options
		endif
		if has_key(info, 'workspace')
			let ni.workspaceConfig = info.workspace
		endif
		if has_key(info, 'root')
			let rootmarkers = []
			for marker in info.root
				call add(rootmarkers, marker)
				call add(rootmarkers, marker . '/')
			endfor
			let ni.rootSearch = rootmarkers
		endif
		call add(servers, ni)
	endfor
	if len(servers) > 0
		" unsilent echom servers
		call LspAddServer(servers)
	endif
	set noshowmode
	set completeopt=menuone,noinsert,noselect
endfunc


"----------------------------------------------------------------------
" buffer initialize
"----------------------------------------------------------------------
function! s:init_buffer() abort
	set completeopt-=popup,preview,popuphidden
endfunc


"----------------------------------------------------------------------
" autocmd
"----------------------------------------------------------------------
augroup YegappanLspInit
	au! 
	autocmd User LspSetup call s:init_lsp()
	autocmd User LspAttached call s:init_buffer()
augroup END


