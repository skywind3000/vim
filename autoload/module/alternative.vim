" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" alternative.vim - locate alternative file
"
" Created by skywind on 2022/09/09
" Last Modified: 2022/09/09 22:25:45
"
"======================================================================


"----------------------------------------------------------------------
" config
"----------------------------------------------------------------------
if !exists('g:alternative')
	let g:alternative = [
				\ "h:c",
				\ "h:m",
				\ "h,hpp,hh:cpp,cc,cxx,mm",
				\ "H:C,M",
				\ "H,HPP,HH:CPP,CC,CXX,MM",
				\ "vim:vim",
				\ "aspx.cs:aspx",
				\ "aspx.vb:aspx",
				\ ]
endif

if !exists('g:alternative_dirs')
	let g:alternative_dirs = [
				\ '../include',
				\ '../inc',
				\ '../h',
				\ '../src',
				\ '../source',
				\ ]
endif


"----------------------------------------------------------------------
" find alternative
"----------------------------------------------------------------------
function! module#alternative#alter_extname(extname) abort
	let hr = []
	let extname = a:extname
	for text in g:alternative
		let text = asclib#string#replace(text, ' ', '')
		let parts = split(text, ':')
		if len(parts) < 2
			continue
		endif
		let p1 = split(parts[0], ',')
		let p2 = split(parts[1], ',')
		if index(p1, extname) >= 0
			let hr += p2
		elseif index(p2, extname) >= 0
			let hr += p1
		endif
	endfor
	return hr
endfunc


"----------------------------------------------------------------------
" detect certain path
"----------------------------------------------------------------------
function! s:detect_path(pattern, altmap)
	let pattern = a:pattern
	let altmap = a:altmap
	" echo pattern
	for name in split(asclib#path#glob(pattern, 1), '\n')
		if name != ''
			let test = fnamemodify(name, ':e')
			" echo "  - " . name
			if has_key(altmap, test)
				return name
			endif
		endif
	endfor
	return ''
endfunc


"----------------------------------------------------------------------
" search alternative
"----------------------------------------------------------------------
function! module#alternative#search(fullname, ...) abort
	let fullname = (a:fullname == '')? expand('%:p') : a:fullname
	let fullname = (a:fullname == '%')? expand('%:p') : fullname
	let fullname = asclib#path#abspath(fullname)
	let mainname = fnamemodify(fullname, ':t:r')
	let extname = fnamemodify(fullname, ':e')
	let dirname = asclib#path#dirname(fullname)
	let root = asclib#path#get_root(fullname)
	if extname == ''
		return ''
	elseif !filereadable(fullname)
		return ''
	endif
	let alter_exts = module#alternative#alter_extname(extname)
	let alter_exts = filter(alter_exts, 'v:val != extname')
	" echo alter_exts
	let alter_dict = {}
	for name in alter_exts
		let alter_dict[name] = 1
	endfor
	let pattern = dirname . '/' . mainname . '.*'
	let t = s:detect_path(pattern, alter_dict)
	if t != ''
		return t
	endif
	for name in g:alternative_dirs
		let test = asclib#path#join(dirname, name)
		let test = asclib#path#normalize(test)
		if isdirectory(test) || 1
			let pattern = test . '/' . mainname . '.*'
			let t = s:detect_path(pattern, alter_dict)
			if t != ''
				return t
			endif
		endif
	endfor
	let level = 0
	let maxlevel = (a:0 > 0)? (a:1) : -1
	while 1
		let pattern = dirname . '/**/' . mainname . '.*'
		let t = s:detect_path(pattern, alter_dict)
		if t != ''
			return t
		endif
		let level += 1
		if asclib#path#equal(dirname, root)
			break
		elseif maxlevel > 0
			if level >= maxlevel
				break
			endif
		endif
		let t = fnamemodify(dirname, ':h')
		if t == dirname
			break
		endif
		let dirname = t
	endwhile
	return ''
endfunc


"----------------------------------------------------------------------
" get current alternative
"----------------------------------------------------------------------
function! module#alternative#get()
	if exists('b:_alternative_name')
		if b:_alternative_name != ''
			if exists(b:_alternative_name)
				return b:_alternative_name
			endif
		endif
		unlet b:_alternative_name
	endif
	let depth = get(g:, 'alternative_depth', -1)
	let hr = module#alternative#search('', depth)
	if hr != ''
		" let b:_alternative_name = hr
	endif
	return hr
endfunc


"----------------------------------------------------------------------
" switch header
"----------------------------------------------------------------------
function! module#alternative#switch(mods, args)
	let hr = module#alternative#get()
	let name = expand('%')
	if hr == ''
		call asclib#core#errmsg('missing alternative for: ' . name)
		return -1
	elseif !filereadable(hr)
		call asclib#core#errmsg('can not read: ' . hr)
		return -2
	endif
	let opts = {}
	if a:mods != ''
		let opts.mods = a:mods
	endif
	if type(a:args) == type('')
		if a:args != ''
			let opts.switch = a:args
		endif
	elseif type(a:args) == type([])
		if len(a:args) > 0
			let opts.switch = join(a:args, ',')
		endif
	endif
	" unsilent echom opts
	call asclib#core#switch(hr, opts)
	return 0
endfunc


"----------------------------------------------------------------------
" command line completion
"----------------------------------------------------------------------
function! module#alternative#complete(ArgLead, CmdLine, CursorPos)
	let candidate = []
	let names = ['useopen', 'usetab', 'edit', 'split', 'vsplit']
	let names += ['newtab', 'auto', 'uselast']
	call sort(names)
	for name in names
		if stridx(name, a:ArgLead) == 0
			let candidate += [name]
		endif
	endfor
	return candidate
endfunc


"----------------------------------------------------------------------
" benchmark
"----------------------------------------------------------------------
function! module#alternative#benchmark()
	let t1 = asclib#core#clock()
	call module#alternative#get()
	return asclib#core#clock() - t1
endfunc


