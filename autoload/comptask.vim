"======================================================================
"
" comptask.vim - 
"
" Created by skywind on 2023/08/03
" Last Modified: 2023/12/11 00:02
"
"======================================================================


"----------------------------------------------------------------------
" Completion Data
"----------------------------------------------------------------------

" key names
let s:text_keys = {
			\ 'command': 'shell command, or EX-command (starting with :)',
			\ 'cwd': "working directory, use `:pwd` when absent",
			\ 'output': '"quickfix" or "terminal"',
			\ 'pos': 'terminal position or the name of a runner', 
			\ 'errorformat': 'error matching rules in the quickfix window',
			\ 'save': 'whether to save modified buffers before task start',
			\ 'option': 'arbitrary string to pass to the runner',
			\ 'focus': 'whether to focus on the task terminal',
			\ 'close': 'to close the task terminal when task is finished',
			\ 'program': 'command modifier',
			\ 'notify': 'notify a message when task is finished',
			\ 'strip': 'trim header+footer in the quickfix',
			\ 'scroll': 'is auto-scroll allowed in the quickfix',
			\ 'encoding': 'task stdin/stdout encoding',
			\ 'once': 'buffer output and flush when job is finished',
			\ 'listed': 'should terminal buffer be listed',
			\ }

let s:text_system = {
			\ 'win32': 'Windows',
			\ 'linux': 'Linux',
			\ 'darwin': 'macOS',
			\ }

let s:macros = { 
			\ 'VIM_FILEPATH': 'File name of current buffer with full path',
			\ 'VIM_FILENAME': 'File name of current buffer without path',
			\ 'VIM_FILEDIR': 'Full path of current buffer without the file name',
			\ 'VIM_FILEEXT': 'File extension of current buffer',
			\ 'VIM_FILETYPE': 'File type (value of &ft in vim)',
			\ 'VIM_FILENOEXT': 
			\ 'File name of current buffer without path and extension',
			\ 'VIM_PATHNOEXT':
			\ 'Current file name with full path but without extension',
			\ 'VIM_CWD': 'Current directory',
			\ 'VIM_RELDIR': 'File path relativize to current directory',
			\ 'VIM_RELNAME': 'File name relativize to current directory',
			\ 'VIM_ROOT': 'Project root directory',
			\ 'VIM_PRONAME': 'Name of current project root directory',
			\ 'VIM_DIRNAME': "Name of current directory",
			\ 'VIM_CWORD': 'Current word under cursor',
			\ 'VIM_CFILE': 'Current filename under cursor',
			\ 'VIM_CLINE': 'Cursor line number in current buffer',
			\ 'VIM_GUI': 'Is running under gui ?',
			\ 'VIM_VERSION': 'Value of v:version',
			\ 'VIM_COLUMNS': "How many columns in vim's screen",
			\ 'VIM_LINES': "How many lines in vim's screen", 
			\ 'VIM_SVRNAME': 'Value of v:servername for +clientserver usage',
			\ 'VIM_PROFILE': 'Current building profile (debug/release/...)',
			\ 'WSL_FILEPATH': '(WSL) File name of current buffer with full path',
			\ 'WSL_FILENAME': '(WSL) File name of current buffer without path',
			\ 'WSL_FILEDIR': 
			\ '(WSL) Full path of current buffer without the file name',
			\ 'WSL_FILEEXT': '(WSL) File extension of current buffer',
			\ 'WSL_FILENOEXT': 
			\ '(WSL) File name of current buffer without path and extension',
			\ 'WSL_PATHNOEXT':
			\ '(WSL) Current file name with full path but without extension',
			\ 'WSL_CWD': '(WSL) Current directory',
			\ 'WSL_RELDIR': '(WSL) File path relativize to current directory',
			\ 'WSL_RELNAME': '(WSL) File name relativize to current directory',
			\ 'WSL_ROOT': '(WSL) Project root directory',
			\ 'WSL_CFILE': '(WSL) Current filename under cursor',
			\ }


let s:text_macros = {}
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')

for key in keys(s:macros)
	let name = printf('$(%s)', key)
	if s:windows == 0
		if stridx(name, 'WSL_') == 0
			continue
		endif
	endif
	let s:text_macros[name] = s:macros[key]
endfor


"----------------------------------------------------------------------
" list envname
"----------------------------------------------------------------------
function! s:list_envname()
	let output = {}
	for name in asyncrun#info#list_envname()
		if !has_key(s:macros, name)
			let key = '$' . name
			let output[key] = '<Environment Variable>'
		endif
	endfor
	return output
endfunc


"----------------------------------------------------------------------
" get context
"----------------------------------------------------------------------
function! s:get_context() abort
	return strpart(getline('.'), 0, col('.') - 1)
endfunc


"----------------------------------------------------------------------
" check tailing space
"----------------------------------------------------------------------
function! s:check_space(context) abort
	return (a:context == '' || a:context =~ '\s\+$')? 1 : 0
endfunc


"----------------------------------------------------------------------
" search candidate
"----------------------------------------------------------------------
function! s:match_complete(prefix, candidate, kind, sort) abort
	let prefix = a:prefix
	if type(a:candidate) == type({})
		let keys = keys(a:candidate)
		let matched = []
		for key in keys(a:candidate)
			if stridx(key, prefix) == 0
				call add(matched, key)
			endif
		endfor
		if a:sort
			call sort(matched)
		endif
		let output = []
		for key in matched
			let text = a:candidate[key]
			let item = {'word':key, 'kind': a:kind, 'menu':text}
			call add(output, item)
		endfor
		return output
	elseif type(a:candidate) == type([])
		let matched = []
		for item in a:candidate
			if type(item) == 1
				let name = item
				let text = ''
			elseif type(item) == 3
				if len(item) >= 2
					let name = item[0]
					let text = item[1]
				elseif len(item) == 1
					let name = item[0]
					let text = ''
				else
					continue
				endif
			else
				continue
			endif
			if stridx(name, prefix) == 0
				call add(matched, [name, text])
			endif
		endfor
		if a:sort
			call sort(matched)
		endif
		let output = []
		for [name, text] in matched
			let item = {'word':name, 'kind': a:kind, 'menu':text}
			call add(output, item)
		endfor
		return output
	endif
endfunc


"----------------------------------------------------------------------
" compfunc 
"----------------------------------------------------------------------
function! comptask#omnifunc(findstart, base) abort
	if a:findstart
		let ctx = s:get_context()
		let matched = strchars(matchstr(ctx, '\w\+$'))
		let pos = col('.')
		if ctx =~ '^\s*#'
			let start = pos - 1
		elseif ctx =~ '^\s*['
			let start = pos - 1
		elseif stridx(ctx, '=') < 0
			let start = pos - matched - 1
		else
			if ctx =~ '\$$'
				let start = pos - 1 - 1
			elseif ctx =~ '\$($'
				let start = pos - 2 - 1
			elseif ctx =~ '\$(\w\+$'
				let start = pos - 2 - matched - 1
			elseif ctx =~ '\$\w\+$'
				let start = pos - 1 - matched - 1
			else
				let start = pos - matched - 1
			endif
		endif
		return start
	else
		let ctx = s:get_context()
		if ctx =~ '^\s*#'
			return v:null
		elseif ctx =~ '^\s*['
			return v:null
		elseif stridx(ctx, '=') < 0
			if stridx(ctx, ':') < 0
				return s:match_complete(a:base, s:text_keys, 'k', 1)
			elseif stridx(ctx, '/') < 0
				if !exists('s:ft_cache')
					let s:ft_cache = asyncrun#info#list_fts()
					call sort(s:ft_cache)
				endif
				return s:match_complete(a:base, s:ft_cache, 'f', 0)
			else
				return s:match_complete(a:base, s:text_system, 's', 1)
			endif
		else
			let keyname = matchstr(ctx, '^\s*\zs\w\+')
			if a:base =~ '^\$'
				let c1 = s:match_complete(a:base, s:text_macros, 'm', 1)
				let c2 = s:match_complete(a:base, s:list_envname(), 'e', 1)
				call extend(c1, c2)
				return c1
			elseif a:base =~ '^\$\w\+'
				return s:match_complete(a:base, s:list_envname(), 'e', 1)
			elseif a:base =~ '^\$('
				return s:match_complete(a:base, s:text_macros, 'm', 1)
			elseif keyname == 'output'
				let candidate = ['quickfix', 'terminal']
				return s:match_complete(a:base, s:text_macros, 'o', 1)
			elseif keyname == 'command'
				if strlen(a:base) >= 1
					if get(s:, 'init_executable', 0) == 0
						let s:list_executable = asyncrun#info#list_executable()
						let s:init_executable = 1
					endif
					return s:match_complete(a:base, s:list_executable, 'x', 1)
				endif
			elseif keyname == 'pos'
				if get(s:, 'init_runner', 0) == 0
					let s:list_runner = asyncrun#info#list_runner()
					let s:init_runner = 1
				endif
				return s:match_complete(a:base, s:list_runner, 'r', 1)
			elseif keyname == 'program'
				if get(s:, 'init_program', 0) == 0
					let s:list_program = asyncrun#info#list_program()
					let s:init_program = 1
				endif
				return s:match_complete(a:base, s:list_program, 'r', 1)
			endif
		endif
		return v:null
	endif
endfunc


"----------------------------------------------------------------------
" feed popup
"----------------------------------------------------------------------
let g:apm_min_length = get(g:, 'apm_min_length', 2)
let g:apm_key_ignore = get(g:, 'apm_key_ignore', [])
let g:apm_trigger = get(g:, 'apm_trigger', "\<c-n>")

function! s:meets_keyword(context)
	if g:apm_min_length <= 0
		return 0
	endif
	let matches = matchlist(a:context, '\(\k\{' . g:apm_min_length . ',}\)$')
	if empty(matches)
		return 0
	endif
	for ignore in g:apm_key_ignore
		if stridx(ignore, matches[1]) == 0
			return 0
		endif
	endfor
	return 1
endfunc

function! s:check_back_space() abort
	  return col('.') < 2 || getline('.')[col('.') - 2]  =~# '\s'
endfunc

function! s:check_omni_avail() abort
	if &omnifunc == ''
		return 0
	endif
	let ctx = s:get_context()
	if ctx =~ '^\s*$'
		return 0
	elseif ctx =~ '\s$'
		return 0
	endif
	let start = call(&omnifunc, [1, ''])
	if start < 0 || start >= col('.') - 1
		return 0
	endif
	let base = strpart(ctx, start)
	let pos = getpos('.')
	let new = [pos[0], pos[1], pos[2] - strchars(base), pos[3]]
	call setpos('.', new)
	let hr = call(&omnifunc, [0, base])
	call setpos('.', pos)
	if type(hr) == type(v:null)
		return 0
	elseif type(hr) == type([])
		if len(hr) == 0
			return 0
		endif
	elseif type(hr) == type({})
		if has_key(hr, 'words')
			if len(hr['words']) == 0
				return 0
			endif
		endif
	endif
	return 1
endfunc

function! s:on_backspace()
	if pumvisible() == 0
		return "\<BS>"
	endif
	let text = matchstr(s:get_context(), '.*\ze.')
	return s:meets_keyword(text)? "\<BS>" : "\<c-e>\<bs>"
endfunc


" autocmd for CursorMovedI
function! s:feed_popup()
	let enable = get(b:, 'apm_enable', 0)
	let lastx = get(b:, 'apm_lastx', -1)
	let lasty = get(b:, 'apm_lasty', -1)
	let tick = get(b:, 'apm_tick', -1)
	let omni = get(b:, 'apm_omni', 0)
	if &bt != '' || enable == 0 || &paste
		return -1
	endif
	let x = col('.') - 1
	let y = line('.') - 1
	if pumvisible()
		let context = s:get_context()
		if s:meets_keyword(context) == 0
			call feedkeys("\<c-e>", 'n')
		endif
		let b:apm_lastx = x
		let b:apm_lasty = y
		let b:apm_tick = b:changedtick
		return 0
	elseif lastx == x && lasty == y
		return -2
	elseif b:changedtick == tick
		let lastx = x
		let lasty = y
		return -3
	endif
	if omni
		if s:check_omni_avail()
			silent! call feedkeys("\<c-x>\<c-o>", 'n')
			let b:apm_lastx = x
			let b:apm_lasty = y
			let b:apm_tick = b:changedtick
			return 0
		endif
	endif
	let context = s:get_context()
	if s:meets_keyword(context)
		if exists('*complete_info') == 1
			let info = complete_info(['mode'])
			if info.mode != ''
				silent! call feedkeys("\<c-e>", 'n')
			endif
		endif
		silent! call feedkeys(get(b:, 'apm_trigger', g:apm_trigger), 'n')
		let b:apm_lastx = x
		let b:apm_lasty = y
		let b:apm_tick = b:changedtick
	endif
	return 0
endfunc

" autocmd for CompleteDone
function! s:complete_done()
	let b:apm_lastx = col('.') - 1
	let b:apm_lasty = line('.') - 1
	let b:apm_tick = b:changedtick
endfunc

" enable apc
function! comptask#complete_enable()
	if !exists('*complete_info')
		return
	endif
	call comptask#complete_disable()
	augroup ApmEventGroup2
		au!
		au CursorMovedI <buffer> nested call s:feed_popup()
		au CompleteDone <buffer> call s:complete_done()
	augroup END
	let b:apm_init_autocmd = 1
	inoremap <silent><buffer><expr> <tab>
				\ pumvisible()? "\<c-n>" :
				\ <SID>check_back_space() ? "\<tab>" : 
				\ get(b:, 'apm_trigger', g:apm_trigger)
	inoremap <silent><buffer><expr> <s-tab>
				\ pumvisible()? "\<c-p>" : "\<s-tab>"
	if get(g:, 'apm_cr_confirm', 0) == 0
		inoremap <silent><buffer><expr> <cr> 
					\ pumvisible()? "\<c-y>\<cr>" : "\<cr>"
	else
		inoremap <silent><buffer><expr> <cr> 
					\ pumvisible()? "\<c-y>" : "\<cr>"
	endif
	inoremap <silent><buffer><expr> <bs> <SID>on_backspace()
	let b:apm_init_tab = 1
	let b:apm_init_bs = 1
	let b:apm_init_cr = 1
	let b:apm_save_infer = &infercase
	setlocal infercase
	let b:apm_enable = 1
endfunc

" disable apc
function! comptask#complete_disable() abort
	if get(b:, 'apm_init_autocmd', 0)
		augroup ApmEventGroup2
			au! 
		augroup END
	endif
	if get(b:, 'apm_init_tab', 0)
		silent! iunmap <buffer><expr> <tab>
		silent! iunmap <buffer><expr> <s-tab>
	endif
	if get(b:, 'apm_init_bs', 0)
		silent! iunmap <buffer><expr> <bs>
	endif
	if get(b:, 'apm_init_cr', 0)
		silent! iunmap <buffer><expr> <cr>
	endif
	if get(b:, 'apm_save_infer', '') != ''
		let &l:infercase = b:apm_save_infer
	endif
	let b:apm_init_autocmd = 0
	let b:apm_init_tab = 0
	let b:apm_init_bs = 0
	let b:apm_init_cr = 0
	let b:apm_save_infer = ''
	let b:apm_enable = 0
endfunc


