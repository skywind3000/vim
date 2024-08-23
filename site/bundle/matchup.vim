" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" matchup.vim - matchup config
"
" Created by skywind on 2022/12/05
" Last Modified: 2022/12/05 13:29:13
"
"======================================================================

" vim-matchup conflicts with matchit, should disable matchit
let g:loaded_matchit = 1

" disable modifying statusline
let g:matchup_matchparen_offscreen = {}

if has('patch-8.1.1500') || has('nvim')
	let g:matchup_matchparen_offscreen.method = 'popup'
endif


" disable modifying statusline
let g:matchup_matchparen_offscreen = {}

