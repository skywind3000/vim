"======================================================================
"
" terminal.vim - terminal buffers
"
" Created by skywind on 2024/03/23
" Last Modified: 2024/03/23 00:37:07
"
"======================================================================

if &bt != 'terminal'
	finish
elseif get(g:, 'asyncrun_term', 0) == 0
	finish
endif

exec printf('nnoremap <buffer>q :<c-u>close<cr>')
exec printf('nnoremap <buffer><m-x> :<c-u>close<cr>')
exec printf('nnoremap <buffer><tab>q :<c-u>close<cr>')

let b:matchup_matchparen_enabled = 0

if exists(':NoMatchParen') == 2
	exec 'NoMatchParen'
endif


