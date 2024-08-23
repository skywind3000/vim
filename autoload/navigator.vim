"======================================================================
"
" navigator.vim - 
"
" Created by skywind on 2023/06/27
" Last Modified: 2023/08/07 14:52
"
"======================================================================


"----------------------------------------------------------------------
" default config
"----------------------------------------------------------------------
let s:config_name = {
			\ 'icon_separator': '=>',
			\ 'icon_group': '+',
			\ 'icon_breadcrumb': '>',
			\ 'max_height': 20,
			\ 'min_height': 5,
			\ 'max_width': 60,
			\ 'min_width': 20,
			\ 'bracket': 0,
			\ 'padding': [2, 0, 2, 0],
			\ 'spacing': 3,
			\ 'vertical': 0,
			\ 'position': 'botright',
			\ 'splitmod': '',
			\ 'popup': 0,
			\ 'popup_position': 'bottom',
			\ 'popup_width': '65%',
			\ 'popup_height': '40%',
			\ 'popup_border': 1,
			\ 'hide_cursor': 0,
			\ 'fallback': 0,
			\ 'timeout': 0,
			\ 'display_path': 0,
			\ }


"----------------------------------------------------------------------
" open and returns key array
"----------------------------------------------------------------------
function! navigator#open(keymap, prefix, ...) abort
	let opts = (a:0 > 0)? deepcopy(a:1) : {}
	for name in keys(s:config_name)
		if !has_key(opts, name)
			let nm = 'navigator_' . name
			if exists('g:' . nm)
				let opts[name] = get(g:, nm, s:config_name[name])
			endif
		endif
	endfor
	let keymap = navigator#config#keymap_expand(a:keymap)
	" let opts.prefix = a:prefix
	let qf = 0
	if navigator#utils#quickfix_check()
		let qf = 1
		if get(opts, 'popup', 0) == 0
			if get(opts, 'vertical') == 0
				call navigator#utils#quickfix_close()
			endif
		endif
	endif
	if has_key(keymap, 'config')
		let config = keymap.config
		if type(config) == type({})
			for name in keys(s:config_name)
				if has_key(config, name)
					let opts[name] = config[name]
				endif
			endfor
		endif
	endif
	if get(opts, 'popup', 0) != 0
		let has_popup = exists('*popup_create') && v:version >= 800
		let has_floatwin = has('nvim-0.4')
		if has('nvim') == 0 && has_popup == 0
			echohl ErrorMsg
			echom 'Navigator Error: popup is not available in this version'
			echohl None
			return []
		elseif has('nvim') && has_floatwin == 0
			echohl ErrorMsg
			echom 'Navigator Error: floatwin is not available in this version'
			echohl None
			return []
		endif
	endif
	let hr = navigator#state#start(keymap, opts)
	if qf != 0
	endif
	return hr
endfunc


"----------------------------------------------------------------------
" start command
"----------------------------------------------------------------------
function! navigator#start(visual, bang, args, line1, line2, count) abort
	let visual = (a:visual)? 'normal! gv' : ''
	let line1 = a:line1
	let line2 = a:line2
	let opts = {}
	if a:args !~ '^\*:[A-Za-z0-9#_]\+$'
		try
			let keymap = eval(a:args)
		catch
			redraw
			echohl ErrorMsg
			echo printf('navigator#start:%s', v:exception)
			echohl None
			return
		endtry
	else
		let oname = strpart(a:args, 2)
		let gname = 'g:' . oname
		let keymap = {}
		if exists(gname)
			let keymap = eval(gname)
			let keymap = navigator#config#keymap_expand(keymap)
			let keymap = deepcopy(keymap)
		endif
		for name in ['b:' . oname, 't:' . oname]
			if exists(name)
				let map2 = eval(name)
				let map2 = navigator#config#keymap_expand(map2)
				let keymap = navigator#utils#merge(keymap, map2)
			endif
		endfor
	endif
	let prefix = get(keymap, 'prefix', '')
	let path = navigator#open(keymap, prefix, opts)
	if path == []
		return 0
	endif
	let hr = navigator#config#visit(keymap, path)
	let range = ''
	if a:visual != 0
		let range = printf("%d,%d", a:line1, a:line2)
	elseif a:line1 != a:line2
		let range = printf("%d,%d", a:line1, a:line2)
	elseif a:count > 0
		let range = printf("%d", a:count)
	endif
	if type(hr) == v:t_list
		try
			if type(hr[0]) == v:t_func
				exec visual
				return call(hr[0], [])
			endif
			let cmd = (len(hr) > 0)? hr[0] : ''
			if cmd =~ '^[a-zA-Z0-9_#]\+(.*)$'
				exec printf('%scall %s', range, cmd)
			elseif cmd =~# '^<key>'
				let keys = strpart(cmd, 5)
				let keys = navigator#charname#mapname(keys)
				exec visual
				call feedkeys(keys)
			elseif cmd =~# '^<KEY>'
				let keys = strpart(cmd, 5)
				let keys = navigator#charname#mapname(keys)
				exec visual
				call feedkeys(keys, 'n')
			elseif cmd =~ '^<plug>'
				let keys = strpart(cmd, 6)
				exec visual
				call feedkeys("\<plug>" . keys)
			else
				exec printf('%s%s', range, cmd)
			endif
		catch
			redraw
			echohl ErrorMsg
			echo v:exception
			echohl None
		endtry
	elseif prefix != ''
		let prefix = navigator#charname#mapname(prefix)
		let keys = s:key_translate([prefix] + path)
		let keys = navigator#charname#mapname(keys)
		exec visual
		" echo printf("keys: '%s'", keys)
		call feedkeys(keys, 'n')
	endif
endfunc


"----------------------------------------------------------------------
" translate key name array to key code string
"----------------------------------------------------------------------
function! s:key_translate(array) abort
	let output = []
	for cc in a:array
		let ch = navigator#charname#get_key_code(cc)
		if ch == ''
			let ch = cc
		endif
		let output += [ch]
	endfor
	return join(output, '')
endfunc


