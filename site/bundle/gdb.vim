"======================================================================
"
" gdb.vim - 
"
" Created by skywind on 2023/06/16
" Last Modified: 2023/06/16 22:26:39
"
"======================================================================


"----------------------------------------------------------------------
" config 
"----------------------------------------------------------------------
let g:termdebug_config = {}

let g:termdebug_config.use_prompt = 1
let g:termdebug_config.map_K = 0
let g:termdebug_config.winbar = 0
let g:termdebug_config.command = 'gdb'
let g:termdebug_config.sign = '>>'


"----------------------------------------------------------------------
" setup key map
"----------------------------------------------------------------------
command! -nargs=0 GdbKeymap call s:GdbKeymap()
function! s:GdbKeymap()
	noremap <c-f5> :Run<cr>
	noremap <c-f6> :Continue<cr>
	noremap <c-f7> :Finish<cr>
	" Over is next
	noremap <c-f8> :Over<cr>
	noremap <c-f9> :GdbToggleBreakpoint<cr>
	noremap <c-f10> :Step<cr>
	noremap <c-f11> :Until<cr>
	noremap <c-f12> :call TermDebugSendCommand('info locals')<cr>
	noremap <c-f1> :GdbHelp<cr>
	noremap <c-f2> :Evaluate<cr>
	noremap <c-f3> :call TermDebugSendCommand('bt')<cr>
	noremap <c-f4> :Step<cr>
	noremap <s-space> :GdbToggleBreakpoint<cr>
endfunc


"----------------------------------------------------------------------
" help window
"----------------------------------------------------------------------
command! -nargs=0 GdbHelp call s:GdbHelp()
function! s:GdbHelp() abort
	let context = [
				\ ["&Run\tCtrl+F5", 'Run'],
				\ ["&Continue\tCtrl+F6", 'Continue'],
				\ ["&Finish\tCtrl+F7", 'Finish'],
				\ ["&Next\tCtrl+F8", 'Over'],
				\ ["--"],
				\ ["&Breakpoint\tCtrl+F9", 'GdbToggleBreakpoint'],
				\ ["&Step\tCtrl+F10", 'Step'],
				\ ["&Until\tCtrl+F11", 'Until'],
				\ ["&Display\tCtrl+F12", 'D info locals'],
				\ ["--"],
				\ ["&Evaluate\tCtrl+F2", 'Evaluate'],
				\ ["B&acktrace\tCtrl+F3", 'D bt'],
				\ ["S&top\tCtrl+F4", 'Stop'],
				\ ]
	call quickui#tools#clever_context('gdb', context, {})
endfunc


"----------------------------------------------------------------------
" start debug
"----------------------------------------------------------------------
command! -nargs=? -complete=file GdbStart call s:GdbStart(<q-args>)
function! s:GdbStart(name) abort
	if !exists(':Termdebug')
		packadd termdebug
	endif
	exec 'Termdebug ' . ((a:name == '')? '' : fnameescape(a:name))
	GdbKeymap
endfunc


"----------------------------------------------------------------------
" query signs in certain line number
"----------------------------------------------------------------------
function! GdbSignQuery(bid, lnum, group)
	let info = sign_getplaced(a:bid, {'group': a:group, 'lnum': a:lnum})
	let query = []
	if type(info) != v:t_list
		return []
	endif
	for items in info
		if type(items) != v:t_dict
			continue
		elseif !has_key(items, 'signs')
			continue
		endif
		let signs = items['signs']
		if type(signs) != v:t_list
			continue
		endif
		for item in signs
			if type(item) != v:t_dict
				continue
			endif
			if item.lnum != a:lnum || item.group != a:group
				continue
			endif
			let query += [item.name]
		endfor
	endfor
	return query
endfunc


"----------------------------------------------------------------------
" toggle break point
"----------------------------------------------------------------------
command! -nargs=* GdbToggleBreakpoint call s:GdbToggleBreakpoint()
function! s:GdbToggleBreakpoint() abort
	if !exists(':Break')
		call asclib#core#errmsg('Termdebug is not loaded')
		return 0
	endif
	if &bt != ''
		call asclib#core#errmsg('Termdebug can not place break point here')
		return 0
	endif
	let bid = bufnr('%')
	let query = GdbSignQuery(bid, line('.'), 'TermDebug')
	let check = 0
	for q in query
		if q =~ '^debugBreakpoint'
			let check = 1
			break
		endif
	endfor
	if check
		Clear
	else
		Break
	endif
endfunc


"----------------------------------------------------------------------
" send command
"----------------------------------------------------------------------
command! -nargs=* D call s:SendCommand(<q-args>)
function! s:SendCommand(command) abort
	return TermDebugSendCommand(a:command)
endfunc


autocmd VimEnter * GdbKeymap



"----------------------------------------------------------------------
" 
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
		noremap <buffer>K :GdbHelp<cr>
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
augroup TermDebugHelp
	au!
	au User TermdebugStartPre call s:term_start_pre()
	au User TermdebugStartPost call s:term_start_post()
	au User TermdebugStopPre call s:term_stop_pre()
	au User TermdebugStopPost call s:term_stop_post()
augroup END


