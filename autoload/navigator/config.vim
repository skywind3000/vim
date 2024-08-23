" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" config.vim - 
"
" Created by skywind on 2022/09/07
" Last Modified: 2023/07/29 23:41
"
"======================================================================


"----------------------------------------------------------------------
" default config
"----------------------------------------------------------------------
let s:default_config = {
			\ 'icon_separator': '=>',
			\ 'icon_group': '+',
			\ 'icon_breadcrumb': '>',
			\ 'max_height': 10,
			\ 'min_height': 5,
			\ 'max_width': 45,
			\ 'min_width': 20,
			\ 'bracket': 0,
			\ 'padding': [2, 0, 2, 0],
			\ 'spacing': 3,
			\ 'vertical': 0,
			\ 'popup': 0,
			\ 'popup_width': '65%',
			\ 'popup_height': '40%',
			\ 'popup_position': 'bottom',
			\ 'popup_border': 1,
			\ 'position': 'botright',
			\ 'fallback': 0,
			\ 'timeout': -1,
			\ 'display_path': 0,
			\ 'splitmod': '',
			\ }


"----------------------------------------------------------------------
" position direction
"----------------------------------------------------------------------
let s:position_dict = {
			\ 'leftabove': 0, 'aboveleft': 0, 'lefta': 0, 'abo': 0,
			\ 'rightbelow': 1, 'belowright': 1, 'rightb': 1, 'bel': 1,
			\ 'topleft': 2, 'to': 2, 'top': 2,
			\ 'botright': 3, 'bo': 3, 'bottom': 3, 'rightbot': 3,
			\ }


"----------------------------------------------------------------------
" get config
"----------------------------------------------------------------------
function! navigator#config#get(opts, key) abort
	if type(a:opts) == v:t_dict
		let opts = a:opts
	else
		let opts = {}
	endif
	return get(opts, a:key, s:default_config[a:key])
endfunc


"----------------------------------------------------------------------
" value store
"----------------------------------------------------------------------
function! navigator#config#store(name, value) abort
	if !exists('s:internal_variable')
		let s:internal_variable = {}
	endif
	let s:internal_variable[a:name] = a:value
endfunc


"----------------------------------------------------------------------
" value fetch
"----------------------------------------------------------------------
function! navigator#config#fetch(name, default) abort
	if !exists('s:internal_variable')
		let s:internal_variable = {}
	endif
	if !has_key(s:internal_variable, a:name)
		return a:default
	endif
	return s:internal_variable[a:name]
endfunc


"----------------------------------------------------------------------
" eval ${...}
"----------------------------------------------------------------------
function! s:keymap_eval(keymap) abort
	let keymap = a:keymap
	if type(keymap) == 2
		let keymap = call(keymap, [])
	elseif type(keymap) == 1
		let keymap = quickui#core#string_strip(keymap)
		if keymap =~ '\v^\%\{(.*)\}$'
			let t = strpart(keymap, 2, strlen(keymap) - 3)
			unlet keymap
			let keymap = eval(t)
		endif
	endif
	return keymap
endfunc


"----------------------------------------------------------------------
" keymap expand
"----------------------------------------------------------------------
function! navigator#config#keymap_expand(keymap) abort
	let keymap = s:keymap_eval(a:keymap)
	if type(keymap) != type({})
		let previous = keymap
		let keymap = {}
		for key in keys(previous)
			let value = previous[key]
			let keymap[key] = navigator#config#keymap_expand(value)
		endfor
	endif
	return keymap
endfunc


"----------------------------------------------------------------------
" read config
"----------------------------------------------------------------------
function! s:config(opts, key) abort
	return navigator#config#get(a:opts, a:key)
endfunc


"----------------------------------------------------------------------
" ljust
"----------------------------------------------------------------------
function! navigator#config#ljust(str, size) abort
	return a:str . repeat(' ', a:size - strwidth(a:str))
endfunc


"----------------------------------------------------------------------
" rjust
"----------------------------------------------------------------------
function! navigator#config#rjust(str, size) abort
	return repeat(' ', a:size - strwidth(a:str)) . a:str
endfunc


"----------------------------------------------------------------------
" translate position
"----------------------------------------------------------------------
function! navigator#config#position(what) abort
	let pos = get(s:position_dict, a:what, 3)
	let position = 'botright'
	if pos < 2
		let position = (pos == 0)? 'leftabove' : 'rightbelow'
	elseif pos < 4
		let position = (pos == 2)? 'topleft' : 'botright'
	else
		let position = 'center'
	endif
	return position
endfunc


"----------------------------------------------------------------------
" visit tree node
"----------------------------------------------------------------------
function! navigator#config#visit(keymap, path) abort
	let keymap = a:keymap
	let path = a:path
	if type(keymap) == type(v:null) || type(path) == type(v:null)
		return v:null
	endif
	let index = 0
	while 1
		let keymap = s:keymap_eval(keymap)
		if index >= len(path)
			break
		endif
		let key = path[index]
		if !has_key(keymap, key)
			return v:null
		endif
		let keymap = keymap[key]
		let index += 1
	endwhile
	return keymap
endfunc


"----------------------------------------------------------------------
" compile keymap into ctx
"----------------------------------------------------------------------
function! navigator#config#compile(keymap, opts) abort
	let keymap = a:keymap
	let opts = a:opts
	let ctx = {}
	let ctx.items = {}
	let ctx.keys = []
	let ctx.strwidth_key = 1
	let ctx.strwidth_txt = 8
	let icon_separator = s:config(a:opts, 'icon_separator')
	let icon_group = s:config(a:opts, 'icon_group')
	for key in keys(keymap)
		if key == '' || key == 'name'
			continue
		endif
		let key_code = navigator#charname#get_key_code(key)
		if key_code == ''
			continue
		endif
		let ctx.keys += [key]
		let item = {}
		let item.key = key
		let item.code = key_code
		let item.label = navigator#charname#get_key_label(key)
		let item.cmd = ''
		let item.text = ''
		let item.child = 0
		let ctx.items[key] = item
		let value = keymap[key]
		if type(value) == v:t_func
			unlet value
			let value = call(value, [])
		elseif type(value) == v:t_string
			let value = quickui#core#string_strip(value)
			if value =~ '\v^\%\{(.*)\}$'
				let t = strpart(value, 2, strlen(value) - 3)
				unlet value
				let value = eval(t)
			endif
		endif
		if type(value) == v:t_string
			let item.cmd = ''
			let item.text = value
		elseif type(value) == v:t_list
			let item.cmd = (len(value) > 0)? value[0] : ''
			let item.text = (len(value) > 1)? value[1] : ''
		elseif type(value) == v:t_dict
			let item.child = 1
			let item.text = get(value, 'name', '...')
		endif
		if item.child
			if stridx(item.text, icon_group) != 0
				let item.text = icon_group . item.text
			endif
		endif
		if strwidth(item.label) > ctx.strwidth_key
			let ctx.strwidth_key = strwidth(item.label)
		endif
		if strwidth(item.text) >= ctx.strwidth_txt
			let ctx.strwidth_txt = strwidth(item.text)
		endif
	endfor
	let ctx.keys = navigator#charname#sort(ctx.keys)
	let bracket = s:config(a:opts, 'bracket')
	if bracket
		if ctx.strwidth_key < 3
			let ctx.strwidth_key = 3
		endif
	endif
	let ctx.stride = ctx.strwidth_key + ctx.strwidth_txt 
	let ctx.stride = ctx.stride + 2 + strwidth(icon_separator)
	for key in ctx.keys
		let item = ctx.items[key]
		let label = item.label
		let text = item.text
		if strlen(label) == 1 && bracket
			let label = '[' . label . ']'
		endif
		let label = navigator#config#rjust(label, ctx.strwidth_key)
		let text = navigator#config#ljust(text, ctx.strwidth_txt)
		if icon_separator != ''
			let item.content = printf('%s %s %s', label, icon_separator, text)
			let item.compact = printf('%s %s %s', label, icon_separator, item.text)
		else
			let item.content = printf('%s %s', label, text)
			let item.compact = printf('%s %s', label, item.text)
		endif
		let item.clength = strwidth(item.compact)
		let stride = strwidth(item.content)
		let ctx.stride = (ctx.stride >= stride)? ctx.stride : stride
	endfor
	let ctx.vertical = navigator#config#get(a:opts, 'vertical')
	let ctx.position = navigator#config#get(a:opts, 'position')
	let ctx.position = navigator#config#position(ctx.position)
	let ctx.popup = navigator#config#get(a:opts, 'popup')
	let ctx.popup_position = navigator#config#get(a:opts, 'popup_position')
	return ctx
endfunc


"----------------------------------------------------------------------
" string to integer
"----------------------------------------------------------------------
function! navigator#config#atoi(text, maxvalue) abort
	let t = a:text
	if type(t) == 0
		return t
	elseif t =~ '%$'
		let x = str2nr(t)
		let y = (x * a:maxvalue) / 100
		return (type(y) != 5)? y : float2nr(y)
	else
		return str2nr(t)
	endif
endfunc


"----------------------------------------------------------------------
" initialize opts
"----------------------------------------------------------------------
function! navigator#config#init(opts) abort
	let opts = deepcopy(a:opts)
	let opts.vertical = navigator#config#get(a:opts, 'vertical')
	let opts.position = navigator#config#get(a:opts, 'position')
	let opts.position = navigator#config#position(opts.position)
	let opts.popup = navigator#config#get(a:opts, 'popup')
	let opts.popup_position = navigator#config#get(a:opts, 'popup_position')
	let w = navigator#config#get(opts, 'popup_width')
	let h = navigator#config#get(opts, 'popup_height')
	let opts.popup_width = navigator#config#atoi(w, &columns)
	let opts.popup_height = navigator#config#atoi(h, &lines)
	if index(['center', 'top'], opts.popup_position) < 0
		let opts.popup_position = 'bottom'
	endif
	if opts.popup
		if g:quickui#core#has_popup == 0
			if g:quickui#core#has_floating == 0
				let opts.popup = 0
			endif
		endif
	endif
	let opts.min_width = navigator#config#get(opts, 'min_width')
	let opts.max_width = navigator#config#get(opts, 'max_width')
	let opts.min_height = navigator#config#get(opts, 'min_height')
	let opts.max_height = navigator#config#get(opts, 'max_height')
	let opts.min_width = navigator#config#atoi(opts.min_width, &columns)
	let opts.max_width = navigator#config#atoi(opts.max_width, &columns)
	let opts.min_height = navigator#config#atoi(opts.min_height, &lines)
	let opts.max_height = navigator#config#atoi(opts.max_height, &lines)
	if opts.min_width > opts.max_width
		let opts.min_width = opts.max_width
	endif
	if opts.min_height > opts.max_height
		let opts.min_height = opts.max_height
	endif
	if opts.popup_position == 'center' && opts.popup != 0
		let opts.min_width = opts.popup_width
		let opts.max_width = opts.popup_width
		let opts.min_height = opts.popup_height
		let opts.max_height = opts.popup_height
	endif
	return opts
endfunc


