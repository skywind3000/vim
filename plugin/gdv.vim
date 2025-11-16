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
	if &bt == ''
		if &ft != 'git'
			" skip normal file buffers
			return 0
		endif
	endif
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
augroup END


