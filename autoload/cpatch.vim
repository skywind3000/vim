"======================================================================
"
" cpatch.vim - help functions
"
" Created by skywind on 2024/01/05
" Last Modified: 2024/01/05 16:29:52
"
"======================================================================


"----------------------------------------------------------------------
" remove style
"----------------------------------------------------------------------
function! cpatch#remove_style(what) abort
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
" 
"----------------------------------------------------------------------
function! cpatch#disable_italic() abort
	call cpatch#remove_style('italic')
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! cpatch#disable_bold() abort
	call cpatch#remove_style('bold')
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! cpatch#remove_background(group) abort
	exe printf('hi %s ctermbg=NONE guibg=NONE', a:group)
endfunc



