"======================================================================
"
" localrc.vim - load local .lvimrc from where your file reside
"
" Created by skywind on 2023/08/18
" Last Modified: 2023/08/18 10:46:42
"
"======================================================================


"----------------------------------------------------------------------
" configuration
"----------------------------------------------------------------------

" file names to source
let g:localrc_name = get(g:, 'localrc_name', ['.lvimrc'])

" set to 1 to search from root to current directory
let g:localrc_reverse = get(g:, 'localrc_reverse', 0)

" set to 0 to disable sandbox
let g:localrc_sandbox = get(g:, 'localrc_sandbox', 1)

" set to 1 to local python script
let g:localrc_python = get(g:, 'localrc_python', 0)

" set to 0 to stop fire autocmd
let g:localrc_autocmd = get(g:, 'localrc_autocmd', 1)

" event to listen
let g:localrc_event = get(g:, 'localrc_event', ["BufWinEnter"])

" event pattern
let g:localrc_pattern = get(g:, 'localrc_pattern', '*')

" force reload
let g:localrc_force = get(g:, 'localrc_force', 0)

" debug
let g:localrc_debug = get(g:, 'localrc_debug', 0)


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let s:is_running = 0
let s:source_uuid = 1
let s:messages = []


"----------------------------------------------------------------------
" buffer local object
"----------------------------------------------------------------------
function! s:debug(level, msg, ...) abort
	if g:localrc_debug >= a:level
		let msg = a:msg
		if a:0 > 0
			let msg .= ' ' . join(a:000, ' ')
		endif
		call add(s:messages, msg)
		let maxsize = get(g:, 'localrc_maxlog', 200)
		if len(s:messages) > maxsize
			call remove(s:messages, 0)
		endif
	endif
endfunc


"----------------------------------------------------------------------
" trigger
"----------------------------------------------------------------------
function! s:autocmd(name) abort
	if g:localrc_autocmd
		call s:debug(7, 'doautocmd', a:name)
		silent exec 'doautocmd User ' . fnameescape(a:name)
	endif
endfunc


"----------------------------------------------------------------------
" path norm case
"----------------------------------------------------------------------
function! s:path_normcase(path) abort
	if s:windows == 0
		return (has('win32unix') == 0)? (a:path) : tolower(a:path)
	else
		return tolower(tr(a:path, '\', '/'))
	endif
endfunc


"----------------------------------------------------------------------
" returns 0 if two path equal to each other,
"----------------------------------------------------------------------
function! s:path_compare(path1, path2) abort
	let p1 = s:path_normcase(a:path1)
	let p2 = s:path_normcase(a:path2)
	return (p1 == p2)? 0 : 1
endfunc


"----------------------------------------------------------------------
" find script
"----------------------------------------------------------------------
function! s:find_script(filename) abort
	let path = fnamemodify(a:filename, ':p:h')
	let rcs = []
	while 1
		for name in g:localrc_name
			if path =~ '[\/\\]$'
				let p = fnamemodify(path . name, ':p')
			else
				let p = fnamemodify(path . '/' . name, ':p')
			endif
			if s:windows
				let p = tr(p, '\', '/')
			endif
			if filereadable(p)
				call add(rcs, p)
			endif
		endfor
		let parent = fnamemodify(path, ':h')
		if s:path_compare(path, parent) == 0
			break
		endif
		let path = parent
	endwhile
	call reverse(rcs)
	if get(g:, 'localrc_reverse', 0)
		call reverse(rcs)
	endif
	if get(g:, 'localrc_count', -1) > 0
		let rcs = slice(rcs, 0, g:localrc_count)
	endif
	return rcs
endfunc


"----------------------------------------------------------------------
" load script
"----------------------------------------------------------------------
function! s:load_script(script, sandbox) abort
	if s:is_running != 0
		call s:debug(2, 'exit nested loading: ', a:script)
		return -1
	endif

	if a:script =~ '\.lua$'
		if has('nvim')
			let cmd = 'luafile ' . fnameescape(a:script)
		elseif has('lua')
			let cmd = 'luafile ' . fnameescape(a:script)
		else
			return -3
		endif
	elseif a:script =~ '\.py$' && g:localrc_python
		if has('python3')
			let cmd = 'py3file ' . fnameescape(a:script)
		elseif has('pythonx')
			let cmd = 'pyxfile ' . fnameescape(a:script)
		elseif has('python2')
			let cmd = 'pyfile ' . fnameescape(a:script)
		else
			return -4
		endif
	else
		let cmd = 'source ' . fnameescape(a:script)
	endif

	if a:sandbox
		let cmd = 'sandbox ' . cmd
	endif

	call s:autocmd('LocalRcPre')

	let s:is_running = 1
	let done = 0

	try
		exec cmd
		let done = 1
	catch
		let msg = v:throwpoint
		let p1 = stridx(msg, '_load_script[')
		if p1 > 0
			let p2 = stridx(msg, ']..', p1)
			if p2 > 0
				let msg = strpart(msg, p2 + 3)
			endif
		endif
		redraw
		echohl ErrorMsg
		echom 'Error detected in ' . msg
		echom v:exception
		echohl None
	endtry

	let s:is_running = 0

	call s:autocmd('LocalRcPost')

	call s:debug(1, 'script loaded:', a:script)

	if done == 0
		return -5
	endif

	return 0
endfunc


"----------------------------------------------------------------------
" match pattern
"----------------------------------------------------------------------
function! s:pattern_match(patterns, str) abort
	for pattern in a:patterns
		try
			if match(a:str, pattern) >= 0
				return 1
			endif
		catch
			echohl ErrorMsg
			echom v:exception
			echohl None
		endtry
	endfor
	return 0
endfunc


"----------------------------------------------------------------------
" local localrc for current source
"----------------------------------------------------------------------
function! s:load_all_script() abort
	let bid = bufnr('%')
	let bname = fnamemodify(bufname(bid), ':p')
	call s:debug(1, 'start loading script for "' . bname . '"')
	if s:is_running != 0
		call s:debug(1, 'already running, exiting')
		return -1
	elseif &bt != ''
		call s:debug(1, 'not a normal buffer, exiting')
		return -2
	endif
	let rcs = s:find_script(bname)
	if len(rcs) == 0
		call s:debug(1, 'not find any local vimrc script, exiting')
		return -3
	endif
	for rcname in rcs
		let rcname = fnamemodify(rcname, ':p')
		let sandbox = g:localrc_sandbox
		call s:debug(3, 'checking:', rcname)
		if exists('g:localrc_blacklist')
			if s:pattern_match(g:localrc_blacklist, rcname)
				call s:debug(2, 'skip black listed script:', rcname)
				continue
			endif
		endif
		if exists('g:localrc_whitelist')
			if !s:pattern_match(g:localrc_whitelist, rcname)
				call s:debug(2, 'skip not white listed script:', rcname)
				continue
			endif
		endif
		if s:path_compare(rcname, bname) == 0
			call s:debug(3, 'skip self script:', rcname)
			continue
		endif
		let code = s:load_script(rcname, sandbox)
	endfor
	let b:__localrc_uuid = s:source_uuid
	return 0
endfunc


"----------------------------------------------------------------------
" check if loading needed
"----------------------------------------------------------------------
command! LocalRcCheck call s:LocalRcCheck()
function! s:LocalRcCheck() abort
	if get(g:, 'localrc_enable', 1) == 0
		call s:debug(1, 'local vimrc disabled, exiting')
		return 0
	endif
	let uuid = get(b:, '__localrc_uuid', -1)
	if uuid == s:source_uuid && g:localrc_force == 0
		call s:debug(2, 'already loaded, exiting')
		return 0
	endif
	call s:load_all_script()
	let b:__localrc_uuid = s:source_uuid
	return 1
endfunc


"----------------------------------------------------------------------
" resource all local vimrc files
"----------------------------------------------------------------------
command! -bang LocalRcLoad call s:LocalRcLoad(<bang>0)
function! s:LocalRcLoad(bang)
	if get(g:, 'localrc_enable', 1) == 0
		call s:debug(1, 'local vimrc disabled, exiting')
		return 0
	endif
	call s:load_all_script()
	if a:bang
		let s:source_uuid += 1
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" display messages or clear
"----------------------------------------------------------------------
command! -bang LocalRcDisplay call s:LocalRcDisplay(<bang>0)
function! s:LocalRcDisplay(bang)
	if a:bang == 0
		for msg in s:messages
			echo '[msg] ' . msg
		endfor
	else
		let s:messages = []
	endif
endfunc


"----------------------------------------------------------------------
" test here
"----------------------------------------------------------------------
function! LocalRcTest()
	LocalRcLoad
	LocalRcDisplay
endfunc


"----------------------------------------------------------------------
" augroup
"----------------------------------------------------------------------
augroup LocalRcAutocmdGroup
	au!
	for event in g:localrc_event
		let cmd = printf('autocmd %s %s ', event, g:localrc_pattern)
		exec cmd . 'call s:LocalRcCheck()'
	endfor
augroup END



