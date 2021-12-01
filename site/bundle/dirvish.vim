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
	exec 'sort ,^.*[\/],'
	let name = '^' . escape(text, '.*[]~\') . '[/*|@=|\\*]\=\%($\|\s\+\)'
	" let name = '\V\^'.escape(text, '\').'\$'
	" echom "search: ".name
	exec "normal gg"
	call search(name, 'wc')
	noremap <silent><buffer> ~ :Dirvish ~<cr>
	noremap <buffer> % :e %
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


