"======================================================================
"
" copilot.vim - 
"
" Created by skywind on 2024/03/18
" Last Modified: 2024/03/18 17:21:18
"
"======================================================================


"----------------------------------------------------------------------
" is copilot enabled for current buffer
"----------------------------------------------------------------------
function! module#copilot#check_enabled() abort
	if &bt != ''
		return 0
	elseif bufname('') == ''
		return 0
	elseif !exists(':Copilot')
		return 0
	elseif exists('b:copilot_enabled')
		return (b:copilot_enabled)? 1 : 0
	elseif exists('g:copilot_filetypes')
		if has_key(g:copilot_filetypes, &ft)
			return (g:copilot_filetypes[&ft])? 1 : 0
		elseif has_key(g:copilot_filetypes, '*')
			return (g:copilot_filetypes['*'])? 1 : 0
		endif
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" setup root
"----------------------------------------------------------------------
function! module#copilot#buffer_init() abort
	if &bt != '' || bufname('') == ''
		return 0
	elseif !module#copilot#check_enabled()
		return 0
	endif
	let root = module#generic#root()
	if !exists('b:workspace_folder')
		if root != ''
			let b:workspace_folder = root
		endif
	endif
	return 0
endfunc


