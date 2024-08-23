"======================================================================
"
" gitcommit.vim - 
"
" Created by skywind on 2024/02/22
" Last Modified: 2024/02/22 23:23:52
"
"======================================================================

let g:context_menu_git_commit = [
			\ ["&Commit", 'exec "wq"'],
			\ ["&Generate Message", 'GptCommit'],
			\ ]

nnoremap <silent><buffer>K :call quickui#tools#clever_context('gc', g:context_menu_git_commit, {})<cr>

