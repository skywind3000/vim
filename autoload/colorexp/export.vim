"======================================================================
"
" export.vim - 
"
" Created by skywind on 2024/02/01
" Last Modified: 2024/02/02 04:22
"
"======================================================================


"----------------------------------------------------------------------
" list highlight
"----------------------------------------------------------------------
function! colorexp#export#list_highlight()
	let colorexp#palette#number = get(g:, 'color_palette_number', 256)
	let output = []
	let names = colorexp#names#collect()
	let convert = get(g:, 'color_export_convert', 1)
	call colorexp#colors#init()
	for name in names
		if hlexists(name)
			let hid = hlID(name)
			let t = colorexp#colors#dump_highlight(hid, convert)
			if stridx(t, '@') < 0
				let output += [t]
			endif
		endif
	endfor
	return output
endfunc

" call colorexp#export#list_highlight()


"----------------------------------------------------------------------
" proceed
"----------------------------------------------------------------------
function! colorexp#export#proceed(name)
	let cname = get(g:, 'colors_name', 'default')
	let tname = fnamemodify(a:name, ':t:r')
	let output = []
	let output += [printf('set background=%s', &background)]
	let output += ['hi clear']
	let output += ['']
	let output += [printf('let g:colors_name = "%s"', tname)]
	let output += ['']
	let output += colorexp#export#list_highlight()
	call writefile(output, a:name)
endfunc



