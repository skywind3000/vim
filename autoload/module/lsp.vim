"======================================================================
"
" lsp.vim - 
"
" Created by skywind on 2023/08/29
" Last Modified: 2023/08/29 17:10:58
"
"======================================================================


"----------------------------------------------------------------------
" check type
"----------------------------------------------------------------------
function! module#lsp#type()
	if exists(':YcmCompleter')
		return 'ycm'
	elseif exists(':CocInstall')
		return 'coc'
	elseif exists(':CmpStatus')
		return 'cmp'
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" hover
"----------------------------------------------------------------------
function! module#lsp#hover() abort
	let tt = module#lsp#type()
	if tt == 'coc'
		if CocAction('hasProvider', 'hover')
			call CocActionAsync('doHover')
		elseif &ft == 'vim'
			call feedkeys('K', 'ni')
		endif
	elseif tt == 'ycm'
		exec "normal \<Plug>(YCMHover)"
	elseif tt == 'cmp'
		lua vim.lsp.buf.hover()
	endif
endfunc


"----------------------------------------------------------------------
" signature help
"----------------------------------------------------------------------
function! module#lsp#signature_help() abort
	let tt = module#lsp#type()
	if tt == 'coc'
	elseif tt == 'cmp'
		lua vim.lsp.buf.signature_help()
	endif
endfunc


"----------------------------------------------------------------------
" get doc
"----------------------------------------------------------------------
function! module#lsp#get_document() abort
	let tt = module#lsp#type()
	if tt == 'ycm'
		exec 'YcmCompleter GetDoc'
	elseif tt == 'coc'
	endif
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#lsp#get_type() abort
	let tt = module#lsp#type()
	if tt == 'ycm'
	elseif tt == 'coc'
	endif
endfunc


"----------------------------------------------------------------------
" goto definition
"----------------------------------------------------------------------
function! module#lsp#goto_definition() abort
	let tt = module#lsp#type()
	if tt == 'ycm'
		exec 'YcmCompleter GoToDefinitionElseDeclaration'
	elseif tt == 'coc'
		call CocActionAsync('jumpDefinition')
	endif
endfunc


"----------------------------------------------------------------------
" goto references
"----------------------------------------------------------------------
function! module#lsp#goto_references() abort
	let tt = module#lsp#type()
	if tt == 'ycm'
		exec 'YcmCompleter GoToReferences'
	elseif tt == 'coc'
		call CocActionAsync('jumpReferences')
	endif
endfunc


"----------------------------------------------------------------------
" goto implementation
"----------------------------------------------------------------------
function! module#lsp#goto_implementation() abort
	let tt = module#lsp#type()
	if tt == 'ycm'
		exec 'YcmCompleter GoToImplementation'
	elseif tt == 'coc'
		call CocActionAsync('jumpImplementation')
	endif
endfunc


"----------------------------------------------------------------------
" goto declaration
"----------------------------------------------------------------------
function! module#lsp#goto_declaration() abort
	let tt = module#lsp#type()
	if tt == 'ycm'
		exec 'YcmCompleter GoToDeclaration'
	elseif tt == 'coc'
		call CocActionAsync('jumpDeclaration')
	endif
endfunc


"----------------------------------------------------------------------
" goto type definition
"----------------------------------------------------------------------
function! module#lsp#goto_type_definition() abort
	let tt = module#lsp#type()
	if tt == 'ycm'
		exec 'YcmCompleter GoToTypeDefinition'
	elseif tt == 'coc'
		call CocActionAsync('jumpTypeDefinition')
	endif
endfunc


