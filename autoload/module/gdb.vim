"======================================================================
"
" gdb.vim - termdebug wrapper
"
" Created by skywind on 2026/10/29
" Last Modified: 2026/10/29 00:26:07
"
"======================================================================


"----------------------------------------------------------------------
" internal states
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')
let s:termdebug_running = 0


"----------------------------------------------------------------------
" return termdebug object for current tabpage
"----------------------------------------------------------------------
function! s:tabpage_object()
	let object = asclib#core#object('t')
	let object.termdebug = get(object, 'termdebug', {})
	return object.termdebug
endfunc


"----------------------------------------------------------------------
" check if termdebug is running
"----------------------------------------------------------------------
function! module#gdb#check_active()
	if !exists(':Termdebug')
		return 0
	endif
	if exists(':ToggleBreakpoint')
		return 1
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" start debug
"----------------------------------------------------------------------
function! module#gdb#start(cmd, bang, args)
	if !exists(':Termdebug')
		packadd termdebug
	endif
	if module#gdb#check_active()
		call asclib#core#errmsg('termdebug is already running, cannot start another instance')
		return
	elseif s:termdebug_running
		call asclib#core#errmsg('termdebug is running, cannot start another instance')
		return
	endif
	if a:cmd != 'Termdebug' && a:cmd != 'TermdebugCommand'
		call asclib#core#errmsg('invalid command: ' . cmd)
		return
	endif
	let g:termdebug_config = get(g:, 'termdebug_config', {})
	let g:termdebug_config.use_prompt = v:true
	let g:termdebug_config.map_K = v:true
	let g:termdebug_config.map_minus = v:false
	let g:termdebug_config.map_plus = v:false
	let g:termdebug_config.winbar = v:false
	let cmdline = printf("%s%s %s", a:cmd, a:bang ? '!' : '', a:args)
	tab split
	let obj = s:tabpage_object()
	let obj.cmdline = cmdline
	let obj.cmd = a:cmd
	let obj.args = a:args
	let obj.running = 1
	exec cmdline
	stopinsert
	let obj.gdb_bid = bufnr('%')
	let obj.gdb_wid = win_getid()
	if s:windows
		exec 'wincmd o'
		exec 'Source'
		exec 'Winbar'
		let obj.source_wid = win_getid()
		exec 'Var'
		exec printf('wincmd w | call win_gotoid(%d)', obj.gdb_wid)
		exec 'normal! i'
	else
		exec 'topleft sp'
		exec 'Source'
		exec 'Winbar'
		let obj.source_wid = win_getid()
		exec 'Var'
		exec 'wincmd p'
		exec 'close'
		exec printf('wincmd w | call win_gotoid(%d)', obj.gdb_wid)
		exec 'normal! i'
	endif
endfunc


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
	let s:termdebug_running = 1
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
	let s:termdebug_running = 0
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


