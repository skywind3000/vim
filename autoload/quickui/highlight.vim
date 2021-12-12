"======================================================================
"
" highlight.vim - 
"
" Created by skywind on 2021/12/12
" Last Modified: 2021/12/12 16:09
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :

"----------------------------------------------------------------------
" term add feature
"----------------------------------------------------------------------
function! quickui#highlight#term_add(info, what)
	let info = a:info
	let what = a:what
	if has_key(info, 'term')
		if type(info.term) == v:t_dict
			let info.term[what] = v:true
		elseif type(info.term) == v:t_string
			let opts = {}
			for key in split(info.term, ',')
				let opts[key] = v:true
			endfor
			let opts[what] = v:true
			let info.term = opts
		endif
	else
		let info.term = {}
		let info.term[what] = v:true
	endif
endfunc


"----------------------------------------------------------------------
" cterm add feature
"----------------------------------------------------------------------
function! quickui#highlight#cterm_add(info, what)
	let info = a:info
	let what = a:what
	if has_key(info, 'cterm')
		if type(info.cterm) == v:t_dict
			let info.cterm[what] = v:true
		elseif type(info.cterm) == v:t_string
			let opts = {}
			for key in split(info.cterm, ',')
				let opts[key] = v:true
			endfor
			let opts[what] = v:true
			let info.cterm = opts
		endif
	else
		let info.cterm = {}
		let info.cterm[what] = v:true
	endif
endfunc


"----------------------------------------------------------------------
" gui add feature
"----------------------------------------------------------------------
function! quickui#highlight#gui_add(info, what)
	let info = a:info
	let what = a:what
	if has_key(info, 'gui')
		if type(info.gui) == v:t_dict
			let info.gui[what] = v:true
		elseif type(info.gui) == v:t_string
			let opts = {}
			for key in split(info.gui, ',')
				let opts[key] = v:true
			endfor
			let opts[what] = v:true
			let info.gui = opts
		endif
	else
		let info.gui = {}
		let info.gui[what] = v:true
	endif
endfunc


"----------------------------------------------------------------------
" new underline
"----------------------------------------------------------------------
function! quickui#highlight#grant_underline(info)
	let info = a:info
	call quickui#highlight#term_add(info, 'underline')
	call quickui#highlight#cterm_add(info, 'underline')
	call quickui#highlight#gui_add(info, 'underline')
	return info
endfunc


"----------------------------------------------------------------------
" add colors
"----------------------------------------------------------------------
function! quickui#highlight#grant_color(info, colors)
	for key in keys(a:colors)
		let a:info[key] = a:colors[key]
	endfor
	return a:info
endfunc


"----------------------------------------------------------------------
" add underline feature
"----------------------------------------------------------------------
function! quickui#highlight#make_underline(newname, name)
	let hr = hlget(a:name, 1)
	if len(hr) == 0
		return -1
	endif
	let info = (len(hr) == 0)? {} : hr[0]
	call quickui#highlight#term_add(info, 'underline')
	call quickui#highlight#cterm_add(info, 'underline')
	call quickui#highlight#gui_add(info, 'underline')
	if has_key(info, 'id')
		unlet info['id']
	endif
	let info.name = a:newname
	let info.force = v:true
	call hlset([info])
	return info
endfunc



"----------------------------------------------------------------------
" combine foreground and background colors
"----------------------------------------------------------------------
function! quickui#highlight#combine(newname, background, foreground)
	let hr1 = hlget(a:background, 1)
	let hr2 = hlget(a:foreground, 1)
	let info1 = empty(hr1)? {} : hr1[0]
	let info2 = empty(hr2)? {} : hr2[0]
	for key in ['ctermfg', 'guifg']
		if has_key(info2, key)
			let info1[key] = info2[key]
		endif
	endfor
	let info1.name = a:newname
	let info1.force = v:true
	call hlset([info1])
endfunc


