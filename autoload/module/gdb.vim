"======================================================================
"
" gdb.vim - termdebug wrapper
"
" Created by skywind on 2026/10/29
" Last Modified: 2026/10/29 00:26:07
"
"======================================================================


"----------------------------------------------------------------------
" start pre:
"----------------------------------------------------------------------
function! s:term_start_pre()
	" echom printf('start_pre: bt=%s bid=%d', &bt, bufnr('%'))
endfunc


"----------------------------------------------------------------------
" start_post: focused on the prompt window
"----------------------------------------------------------------------
function! s:term_start_post()
	" echom printf('start_post: bt=%s bid=%d', &bt, bufnr('%'))
	if &bt == 'prompt'
		setlocal bufhidden=wipe
		exec 'setlocal listchars=tab:\ \ '
		" noremap <buffer>K :GdbHelp<cr>
	endif
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! s:term_stop_pre()
	" echom printf('stop_pre: bt=%s bid=%d', &bt, bufnr('%'))
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! s:term_stop_post()
	" echom printf('stop_post: bt=%s bid=%d', &bt, bufnr('%'))
endfunc


"----------------------------------------------------------------------
" autocmd
"----------------------------------------------------------------------
augroup TermDebugWrapper
	au!
	au User TermdebugStartPre call s:term_start_pre()
	au User TermdebugStartPost call s:term_start_post()
	au User TermdebugStopPre call s:term_stop_pre()
	au User TermdebugStopPost call s:term_stop_post()
augroup END


