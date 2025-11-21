"======================================================================
"
" gdv.vim - 
"
" Created by skywind on 2025/11/16
" Last Modified: 2025/11/16 15:10:05
"
"======================================================================


"----------------------------------------------------------------------
" command implementation
"----------------------------------------------------------------------
function! s:GitDiffView(...) abort
	let commit = (a:0 >= 1)? a:1 : ''
	call gdv#diffview#start(commit)
endfunc


"----------------------------------------------------------------------
" initialize buffer keymaps
"----------------------------------------------------------------------
function! s:gdv_buffer_init() abort
	let keymap = get(g:, 'gdv_keymap', 'dd')
	if keymap == ''
		return 0
	endif
	" Support normal file buffers with filetype=git
	if &bt == ''
		if &ft != 'git'
			" skip normal file buffers that are not git type
			return 0
		endif
	endif
	" Support nowrite buffers with filetype=git (fugitive git log output)
	" These are temporary windows created by :Git log commands like
	" :Git log --oneline or :Git log --graph --oneline --all --decorate
	" Note: buftype=nowrite, filetype=git windows are supported
	exec printf('nnoremap <buffer> %s :GitDiffView<cr>', keymap)
	return 0
endfunc


"----------------------------------------------------------------------
" command definition
"----------------------------------------------------------------------
command! -nargs=? GitDiffView call s:GitDiffView(<f-args>)


"----------------------------------------------------------------------
" autocommands
"----------------------------------------------------------------------
augroup gdv_plugin
	autocmd!
	autocmd FileType fugitive call s:gdv_buffer_init()
	autocmd FileType GV call s:gdv_buffer_init()
	autocmd FileType floggraph call s:gdv_buffer_init()
	autocmd FileType qf call s:gdv_buffer_init()
	autocmd FileType git call s:gdv_buffer_init()
	autocmd FileType vim-plug call s:gdv_buffer_init()
augroup END


