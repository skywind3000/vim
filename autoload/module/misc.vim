"----------------------------------------------------------------------
" save compiler
"----------------------------------------------------------------------
function! s:compiler_save()
	let saved = {}
	let saved.l_makeprg = &l:makeprg
	let saved.g_makeprg = &g:makeprg
	let saved.l_errorformat = &l:errorformat
	let saved.g_errorformat = &g:errorformat
	let saved.bid = bufnr()
	if exists('b:current_compiler')
		let saved.old_compiler = b:current_compiler
	endif
	return saved
endfunc


"----------------------------------------------------------------------
" restore compiler
"----------------------------------------------------------------------
function! s:compiler_restore(saved)
	let saved = a:saved
	let bid = saved.bid
	let &g:makeprg = saved.g_makeprg
	let &g:errorformat = saved.g_errorformat
	call setbufvar(bid, '&makeprg', saved.l_makeprg)
	call setbufvar(bid, '&errorformat', saved.l_errorformat)
	if has_key(saved, 'old_compiler')
		call setbufvar(bid, 'current_compiler', saved.old_compiler)
	else
		if bufnr() == bid
			if exists('b:current_compiler')
				unlet b:current_compiler
			endif
		else
			call setbufvar(bid, 'current_compiler', '')
		endif
	endif
endfunc


"----------------------------------------------------------------------
" open config
"----------------------------------------------------------------------
function! module#misc#open(name) abort
	let p = a:name
	if stridx(p, '~') >= 0
		let p = expand(p)
	endif
	call asclib#utils#file_switch(['-switch=useopen,auto', p])
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#misc#emake_list() abort
	let p = expand('~/.config/emake')
	let candidate = []
	for t in asclib#path#list(p, '*.ini', 1)
		let t = fnamemodify(t, ':t:r')
		let candidate += [t]
	endfor
	return candidate
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#misc#emake_config() abort
	let candidate = module#misc#emake_list()
	let msg = 'Select emake configuration'
	let choice = []
	let index = 0
	let key = 'econfig'
	for c in ['(clear)'] + candidate
		let t = printf('[&%d] %s', index, c)
		let choice += [t]
		let index += 1
	endfor
	let n = 1
	if !exists('g:asynctasks_environ')
		let g:asynctasks_environ = {}
	endif
	let current = get(g:asynctasks_environ, key, '')
	let index = 1
	for t in candidate
		if current == t
			let n = index + 1
			break
		endif
		let index += 1
	endfor
	let hr = asclib#ui#confirm(msg, join(choice, "\n"), n) - 1
	if hr == 0
		let g:asynctasks_environ[key] = ''
		exec ':AsyncTaskEnviron! ' . key
	elseif hr > 0
		exec ':AsyncTaskEnviron ' . key . ' ' . candidate[hr - 1]
	endif
endfunc


"----------------------------------------------------------------------
" set variable for asynctask
"----------------------------------------------------------------------
function! module#misc#task_variable(name, value) abort
	let g:asynctasks_environ = get(g:, 'asynctasks_environ', {})
	let g:asynctasks_environ[a:name] = a:value
endfunc


