let s:windows = has('win32') || has('win16') || has('win95') || has('win64')


function! s:list_script()
	let path = get(g:, 'vimmake_path', expand('~/.vim/script'))
	let names = []
	if s:windows
		for name in split(glob(vimmake#path_join(path, '*.cmd')), '\n')
			let item = {}
			let item.name = fnamemodify(name, ':t')
			let item.path = name
			let item.cmd = 'call '. shellescape(name)
			if item.name =~ '^vimmake\.'
				continue
			endif
			let names += [item]
		endfor
		for name in split(glob(vimmake#path_join(path, '*.bat')), '\n')
			let item = {}
			let item.name = fnamemodify(name, ':t')
			let item.path = name
			let item.cmd = 'call '. shellescape(name)
			let names += [item]
		endfor
	else
		for name in split(glob(vimmake#path_join(path, '*.sh')), '\n')
			let item = {}
			let item.name = fnamemodify(name, ':t')
			let item.path = name
			let item.cmd = 'bash ' . shellescape(name)
			let names += [item]
		endfor
	endif

	for name in split(glob(vimmake#path_join(path, '*.py')), '\n')
		let item = {}
		let item.name = fnamemodify(name, ':t')
		let item.path = name
		let item.cmd = 'python ' . shellescape(name)
		let names += [item]
	endfor

	for name in split(glob(vimmake#path_join(path, '*.rb')), '\n')
		let item = {}
		let item.name = fnamemodify(name, ':t')
		let item.path = name
		let item.cmd = 'ruby ' . shellescape(name)
		let names += [item]
	endfor

	for name in split(glob(vimmake#path_join(path, '*.pl')), '\n')
		let item = {}
		let item.name = fnamemodify(name, ':t')
		let item.path = name
		let item.cmd = 'perl ' . shellescape(name)
		let names += [item]
	endfor

	return names
endfunc


function! asclib#common#script_menu()
	if &bt == 'nofile' && &ft == 'quickmenu'
		call quickmenu#toggle(0)
		return
	endif
	call quickmenu#current('script')
	call quickmenu#reset()

	call quickmenu#append('# Scripts', '')
	
	for item in s:list_script()
		let cmd = 'VimMake -raw ' . item.cmd
		call quickmenu#append(item.name, cmd, 'run ' . item.name)	
	endfor

	call quickmenu#toggle('script')
endfunc





