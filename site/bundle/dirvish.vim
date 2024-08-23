"----------------------------------------------------------------------
" dirvish
"----------------------------------------------------------------------
function! s:setup_dirvish()
	if &buftype != 'nofile' && &filetype != 'dirvish'
		return
	endif
	let text = getline('.')
	if ! get(g:, 'dirvish_hide_visible', 0)
		exec 'silent keeppatterns g@\v[\/]\.[^\/]+[\/]?$@d _'
	endif
	let d = get(b:, 'dirvish', {})
	let test = get(d, 'lastpath', '')
	if has('win32') || has('win64') || has('win95') || has('win16')
		let test = substitute(test, '\/', '\\', 'g')
		if has('nvim') && test != ''
			let text = test
		endif
	endif
	let name = '^' . escape(text, '.*[]~\') . '[/*|@=|\\*]\=\%($\|\s\+\)'
	" let name = '\V\^'.escape(text, '\').'\$'
	exec 'sort ,^.*[\/],'
	exec "normal gg"
	call search(name, 'wc')
	noremap <silent><buffer> ~ :Dirvish ~<cr>
	noremap <buffer> % :e %
	setlocal cursorline
	if exists('+cursorlineopt')
		setlocal cursorlineopt=both
	endif
endfunc

function! DirvishSetup()
	let text = getline('.')
	for item in split(&wildignore, ',')
		let xp = glob2regpat(item)
		exec 'silent keeppatterns g/'.xp.'/d'
	endfor
	if ! get(g:, 'dirvish_hide_visible', 0)
		exec 'silent keeppatterns g@\v[\/]\.[^\/]+[\/]?$@d _'
	endif
	exec 'sort ,^.*[\/],'
	let name = '^' . escape(text, '.*[]~\') . '[/*|@=]\=\%($\|\s\+\)'
	" let name = '\V\^'.escape(text, '\').'\$'
	call search(name, 'wc')
endfunc

" let g:dirvish_mode = 'call DirvishSetup()'


"----------------------------------------------------------------------
" augroup
"----------------------------------------------------------------------
augroup MyPluginSetup
	autocmd!
	autocmd FileType dirvish call s:setup_dirvish()
augroup END


