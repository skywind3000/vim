let s:script_name = expand('<sfile>:p')
let s:script_home = fnamemodify(s:script_name, ':h')
let s:preload_home = s:script_home . '/../autoload/preload'
let s:preload_home = substitute(s:preload_home, '\\', '/', 'g')

let s:script_available = {}
let s:script_names = []

function! s:scan_script() abort
	let s:script_available = {}
	let scripts = globpath(s:preload_home, '*.vim', 1, 1)
	for name in scripts
		if filereadable(name)
			let key = fnamemodify(name, ':p:t:r')
			let s:script_available[key] = name
		endif
	endfor
	let s:script_names = keys(s:script_available)
	call sort(s:script_names)
endfunc

function! s:convert_to_list(value) abort
	let hr = []
	let value = a:value
	if type(value) == type([])
		let hr = deepcopy(value)
	elseif type(value) == type({})
		for key in keys(value)
			if value[key]
				let hr += [key]
			endif
		endfor
	elseif type(value) == type('')
		for key in split(value, ',')
			let k = substitute(key, '^\s*\(.\{-}\)\s*$', '\1', '')
			let hr += [k]
		endfor
	endif
	return hr
endfunc

function! s:load_script() abort
	let enabled = []
	let disable = {}
	if exists('g:preload_list') == 0
		for name in s:script_names
			let enabled += [name]
		endfor
	else
		let pending = s:convert_to_list(g:preload_list)
		for name in pending
			if !has_key(s:script_available, name)
				echohl ErrorMsg
				echom 'ERROR: invalid name in g:preload_list: ' . name
				echohl None
			else
				let enabled += [name]
			endif
		endfor
	endif
	if exists('g:preload_disable')
		let pending = s:convert_to_list(g:preload_disable)
		for name in pending
			let disable[name] = 1
		endfor
	endif
	for name in enabled
		if !has_key(disable, name)
			let script = s:script_available[name]
			exec 'source ' . fnameescape(script)
		endif
	endfor
	return 1
endfunc


call s:scan_script()
call s:load_script()


