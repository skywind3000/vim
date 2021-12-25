"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#misc#init()
endfunc


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


