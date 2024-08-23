"======================================================================
"
" style.vim - 
"
" Created by skywind on 2022/11/20
" Last Modified: 2022/11/20 22:38:14
"
"======================================================================


"----------------------------------------------------------------------
" remove style
"----------------------------------------------------------------------
function! asclib#style#remove_style(what)
	let need = ['underline', 'undercurl', 'reverse', 'inverse', 'italic']
	call extend(need, ['standout', 'bold'])
	call filter(need, 'v:val != a:what')
	let hid = 1
	while 1
		let hln = synIDattr(hid, 'name')
		if !hlexists(hln) | break | endif
		if hid == synIDtrans(hid) 
			let change = ''
			for mode in ['gui', 'term', 'cterm']
				if synIDattr(hid, a:what, mode)
					let atr = deepcopy(need)
					call filter(atr, 'synIDattr(hid, v:val, mode)')
					let result = empty(atr) ? 'NONE' : join(atr, ',')
					let change .= printf(' %s=%s', mode, result)
				endif
			endfor
			if change != ''
				exec 'highlight ' . hln . ' ' . change
			endif
		endif
		let hid += 1
	endwhile
endfunc


"----------------------------------------------------------------------
" disable italic
"----------------------------------------------------------------------
function! asclib#style#disable_italic()
	let his = ''
	redir => his
	silent hi
	redir END
	let his = substitute(his, '\n\s\+', ' ', 'g')
	for line in split(his, "\n")
		if line !~ ' links to ' && line !~ ' cleared$'
			let t = substitute(line, ' xxx ', ' ', '')
			exe 'hi' substitute(t, 'italic', 'none', 'g')
		endif
	endfor
endfunc



"----------------------------------------------------------------------
" remove bgcolor
"----------------------------------------------------------------------
function! asclib#style#remove_bgcolor(group)
	exe printf('hi %s ctermbg=NONE guibg=NONE', a:group)
endfunc


